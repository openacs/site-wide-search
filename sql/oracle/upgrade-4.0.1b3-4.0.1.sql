-- Internationalization fix , changed from char varchar2(1) to varchar(2)

show errors

-- Query to take free text user entered query and from it into something
-- that will make interMedia happy. Provided by Oracle.
create or replace function im_convert(
    query in varchar2 default null
) return varchar2
is
    i   number :=0;
    len number :=0;
    char varchar2(2);
    minusString varchar2(256) := '';
    plusString varchar2(256) := ''; 
    mainString varchar2(256) := ''; 
    mainAboutString varchar2(500) := ''; 
    finalString varchar2(500) := ''; 
    hasMain number :=0;
    hasPlus number :=0;
    hasMinus number :=0;
    token varchar2(256);
    tokenStart number :=1;
    tokenFinish number :=0;
    inPhrase number :=0;
    inPlus number :=0;
    inWord number :=0;
    inMinus number :=0;
    completePhrase number :=0;
    completeWord number :=0;
    code number :=0;  
begin
  
    len := length(query);

    -- we iterate over the string to find special web operators
    for i in 1..len loop
	char := substr(query,i,1);
	if(char = '"') then
	    if(inPhrase = 0) then
		inPhrase := 1;
		tokenStart := i;
	    else
		inPhrase := 0;
		completePhrase := 1;
		tokenFinish := i-1;
	    end if;
	elsif(char = ' ') then
	    if(inPhrase = 0) then
		completeWord := 1;
		tokenFinish := i-1;
	    end if;
	elsif(char = '+') then
	    inPlus := 1;
	    tokenStart := i+1;
	elsif((char = '-') and (i = tokenStart)) then
	    inMinus :=1;
	    tokenStart := i+1;
	end if;

	if(completeWord=1) then
	    token := '{ '||substr(query,tokenStart,tokenFinish-tokenStart+1)||' }';      
	    if(inPlus=1) then
		im_convert_length_check(plusString, 4+length(token), 256, 'plusString');
		plusString := plusString||','||token||'*10';
		hasPlus :=1;	
	    elsif(inMinus=1) then
		im_convert_length_check(minusString, 4+length(token), 256, 'minusString');
		minusString := minusString||'OR '||token||' ';
		hasMinus :=1;
	    else
		im_convert_length_check(mainString, 6+length(token), 256, 'mainString');
		mainString := mainString||' NEAR '||token;
		im_convert_length_check(mainAboutString, 1+length(token), 500, 'mainAboutString');
		mainAboutString := mainAboutString||' '||token; 
		hasMain :=1;
	    end if;
	    tokenStart  :=i+1;
	    tokenFinish :=0;
	    inPlus := 0;
	    inMinus :=0;
	end if;
	completePhrase := 0;
	completeWord :=0;
    end loop;

    -- find the last token
    token := '{ '||substr(query,tokenStart,len-tokenStart+1)||' }';
    if(inPlus=1) then
	im_convert_length_check(plusString, 4+length(token), 256, 'plusString');
	plusString := plusString||','||token||'*10';
	hasPlus :=1;	
    elsif(inMinus=1) then
	im_convert_length_check(minusString, 4+length(token), 256, 'minusString');
	minusString := minusString||'OR '||token||' ';
	hasMinus :=1;
    else
	im_convert_length_check(mainString, 6+length(token), 256, 'mainString');
	mainString := mainString||' NEAR '||token;
	im_convert_length_check(mainAboutString, 1+length(token), 500, 'mainAboutString');
	mainAboutString := mainAboutString||' '||token; 
	hasMain :=1;
    end if;

  
    mainString := substr(mainString,6,length(mainString)-5);
    mainAboutString := replace(mainAboutString,'{',' ');
    mainAboutString := replace(mainAboutString,'}',' ');
    mainAboutString := replace(mainAboutString,')',' ');	
    mainAboutString := replace(mainAboutString,'(',' ');
    plusString := substr(plusString,2,length(plusString)-1);
    minusString := substr(minusString,4,length(minusString)-4);

    -- let's just check once for the length of finalString... note this uses the 
    -- longest possible string that is created in the rest of this function
    im_convert_length_check(finalString, nvl(length(mainString),0) + nvl(length(mainAboutString),0) + nvl(length(minusString),0) + nvl(length(plusString),0) + 30, 500, 'finalString');

    -- we find the components present and then process them based on the specific combinations
    code := hasMain*4+hasPlus*2+hasMinus;
    if(code = 7) then
	finalString := '('||plusString||','||mainString||'*2.0,about('||mainAboutString||')*0.5) NOT ('||minusString||')';
    elsif (code = 6) then  
	finalString := plusString||','||mainString||'*2.0'||',about('||mainAboutString||')*0.5';
    elsif (code = 5) then  
	finalString := '('||mainString||',about('||mainAboutString||')) NOT ('||minusString||')';
    elsif (code = 4) then  
	finalString := mainString; 
	finalString := replace(finalString,'*1,',NULL); 
	finalString := '('||finalString||')*2.0,about('||mainAboutString||')';
    elsif (code = 3) then  
	finalString := '('||plusString||') NOT ('||minusString||')';
    elsif (code = 2) then  
	finalString := plusString;
    elsif (code = 1) then  
	-- not is a binary operator for intermedia text
	finalString := 'totallyImpossibleString'||' NOT ('||minusString||')';
    elsif (code = 0) then  
	finalString := '';
    end if;

    return finalString;
end;
/

show errors


-- Made changes to to cr revision interface -------------------

create or replace package content_revision__sws
is
    function sws_title (
	object_id		in acs_objects.object_id%TYPE
    ) return varchar2;

    function sws_url (
	object_id           in acs_objects.object_id%TYPE
    ) return varchar2;

    function sws_summary (
	object_id		in acs_objects.object_id%TYPE
    ) return varchar2;    

    function sws_req_permission (
	object_id		in acs_objects.object_id%TYPE
    ) return varchar2;

    function sws_site_node_id (
	object_id           in acs_objects.object_id%TYPE
    ) return site_nodes.node_id%TYPE;

    function sws_application_id (
	object_id	    in acs_objects.object_id%TYPE
    ) return apm_packages.package_id%TYPE;

    procedure sws_index_proc (
	object_id	    in acs_objects.object_id%TYPE,
	bdata		in out nocopy BLOB
    );
   
    -- function returns the application_id that is one of the owners of privilege
    function get_application_owner (
        revision_id         in cr_revisions.revision_id%TYPE
    ) return apm_packages.package_id%TYPE;

    function run_get_application (
        function_name     in varchar2   ,
        revision_id       in cr_revisions.revision_id%TYPE
    ) return apm_packages.package_id%TYPE;
end content_revision__sws;
/

create or replace package body content_revision__sws 
is
    function sws_title (
	object_id		in acs_objects.object_id%TYPE
    ) return varchar2
    is
	v_title		varchar2(1000);
    begin
	select title into v_title 
	from cr_revisions
	where revision_id = object_id;

	return v_title;
    end;

    function sws_url (
	object_id           in acs_objects.object_id%TYPE
    ) return varchar2
    is 
        url                 varchar2(3000);     
	v_item_id	    number;
	v_package_id        number;
        v_package_key       apm_packages.package_key%TYPE;
        v_node_id           site_nodes.node_id%TYPE;
    begin 

	v_node_id := content_revision__sws.sws_site_node_id (object_id);

        if v_node_id is null then 
           return null;
        end if;

        v_package_id := content_revision__sws.sws_application_id (object_id);

	select package_key 
        into   v_package_key 
        from   apm_packages 
        where  package_id = v_package_id;

        url := site_node.url(v_node_id);

        url := url || pot_service.get_obj_type_attr_value (
	       package_key 	    => v_package_key,
               object_type          => 'content_revision',
               attribute            => 'display_page'
        );

	select item_id into v_item_id
	from cr_revisions
	where revision_id = object_id;
	
        return url||to_char(v_item_id);
    end sws_url;

    function sws_summary (
	object_id		in acs_objects.object_id%TYPE
    ) return varchar2
    is
	v_summary	    varchar2(4000);
    begin
	select description into v_summary
	from cr_revisions
	where revision_id = object_id;

	return v_summary;
    end sws_summary;

    function sws_req_permission (
	object_id		in acs_objects.object_id%TYPE
    ) return varchar2 
    is
    begin
	return null;
    end;

    function sws_site_node_id (
	object_id           in acs_objects.object_id%TYPE
    ) return site_nodes.node_id%TYPE
    is
        v_node_id             site_nodes.node_id%TYPE;
        v_package_id          apm_packages.package_id%TYPE;
    begin
        v_node_id := null;
        -- get the application
        v_package_id := content_revision__sws.sws_application_id (
                            object_id => object_id
                        );

        if v_package_id is null then
           return null;
        end if;

        select node_id
        into v_node_id 
        from site_nodes
        where object_id = v_package_id;

        return v_node_id;         
        
        exception 
            when no_data_found then
                return null;
    end;


    function sws_application_id (
	object_id	    in acs_objects.object_id%TYPE
    ) return apm_packages.package_id%TYPE
    is
        v_application_id        apm_packages.package_id%TYPE;
    begin
        v_application_id := content_revision__sws.get_application_owner (
                                revision_id  => object_id 
                            );
        return v_application_id;
    end;

    procedure sws_index_proc (
	object_id	    in acs_objects.object_id%TYPE,
	bdata		in out nocopy BLOB
    ) 
    is
	v_bdata		    BLOB;
	v_content_length    number;
    begin

	select	content	    ,
		dbms_lob.getlength(content)
	into	v_bdata,
		v_content_length
	from cr_revisions
	where revision_id = object_id;

	if v_content_length > 0 then
	    dbms_lob.copy  (
		dest_lob    => bdata	,
		src_lob	    => v_bdata	,
		amount	    => v_content_length
	    );
	end if;
    end;

    function get_application_owner (
        revision_id         in cr_revisions.revision_id%TYPE
    )   return apm_packages.package_id%TYPE
    is
	v_package_id    apm_packages.package_id%TYPE;
    begin
	v_package_id := null;
        for method_row in (select attribute_value 
                           from pot_map_attr_values
                           where object_type = 'content_revision'
                           and attribute = 'cr_revision_in_package_id') loop

            v_package_id  := content_revision__sws.run_get_application (
                                 function_name => method_row.attribute_value,
                                 revision_id   => revision_id
                             );

            if v_package_id is not null then
                return v_package_id;
            end if;
        end loop;
        return v_package_id;
    end;

    function run_get_application (
        function_name     in varchar2,
        revision_id       in cr_revisions.revision_id%TYPE
    ) return apm_packages.package_id%TYPE
    is
	v_package_id    apm_packages.package_id%TYPE;
        v_code          varchar2(4000);
	v_cursor        integer;
        v_result        integer;
    begin
        v_cursor :=dbms_sql.OPEN_CURSOR;

        v_code := 'select '||function_name||'(:revision_id) from dual';                       

        execute immediate v_code into v_package_id using revision_id;
        
        return v_package_id;

        exception 
           when others then
               return null;        
    end;
end content_revision__sws;
/

-- add attribute for content revision type
begin 
    pot_service.create_attribute (
        attribute       => 'cr_revision_in_package_id',
        description     => 'Used by content revision object to ask applications whether they 
                            are one of the owners of the content revision item. This method takes
                            one parameter, revision_id, and returns the package instance id that "owns" it.'
    );
end;
/



create or replace package body sws_service as

    -- the first 6 are wrapper functions for the 'sws_display' interface methods    
    function get_content_node_id (                                                 
	content_id in sws_search_contents.content_id%TYPE                              
    ) return sws_search_contents.node_id%TYPE                                   
    is                                                                          
	v_node_id		sws_search_contents.node_id%TYPE;                               
  	v_code			varchar2(4000);                    
     	v_object_type		acs_object_types.object_type%TYPE;   
        v_result		integer;                                               
    begin                                                                       
                                                                                
	v_object_type := acs_object_util.get_object_type (                             
	    object_id => content_id                                                    
	);                                                                             
        

	v_object_type := acs_interface.obj_provide_implement (
	    interface_name	    => 'sws_display',
	    programming_language    => 'pl/sql',
	    object_type		    => v_object_type );


	-- construct dynamic sql to invoke the sws_site_node_id method within the object type package
	-- object types are searchable only if they implement the interface

        v_code := 'select '||v_object_type||'.sws_site_node_id(:content_id) from dual';
	execute immediate v_code into v_node_id using content_id;
                                                                   
	return v_node_id;        
	exception
	    when others then
		return null;
                                                      
    end get_content_node_id;                                                                        
                                                                                
    function get_content_application_id (                                          
	content_id in		sws_search_contents.content_id%TYPE                              
    ) return sws_search_contents.application_id%TYPE                            
    is                                                                          
	v_cursor_id		integer;                                                          
	v_application_id	sws_search_contents.application_id%TYPE;                      
	v_code			varchar2(4000);                                                    
	v_object_type		acs_object_types.object_type%TYPE;                              
	v_result		integer;                                                             
    begin                                                                       
                                                                                
	v_object_type := acs_object_util.get_object_type (                             
	    object_id => content_id                                                    
	);                                                                             

	v_object_type := acs_interface.obj_provide_implement (
	    interface_name	    => 'sws_display',
	    programming_language    => 'pl/sql',
	    object_type		    => v_object_type );

        v_code := 'select '||v_object_type||'.sws_application_id(:content_id) from dual';
	-- construct dynamic sql to invoke the sws_application_id method within the object type package
	-- object types are searchable only if they implement the interface
	execute immediate v_code into v_application_id using content_id;
                                                          
	return v_application_id;                                                       
	exception
	    when others then
		return null;

    end get_content_application_id;                                                                        
                                                                                
    function get_content_permission (                                           
	content_id in sws_search_contents.content_id%TYPE                              
    ) return sws_search_contents.permission_req%TYPE                            
    is                                                                          
	v_cursor_id		integer;                                                          
	v_permission		sws_search_contents.permission_req%TYPE;                         
	v_code			varchar2(4000);                                                       
	v_object_type		acs_object_types.object_type%TYPE;                              
	v_result		integer;                                                               
    begin                                                                       
                                                                                
	v_object_type := acs_object_util.get_object_type (                             
	    object_id => content_id                                                    
	);                                                                             

	v_object_type := acs_interface.obj_provide_implement (
	    interface_name	    => 'sws_display',
	    programming_language    => 'pl/sql',
	    object_type		    => v_object_type );


        v_code := 'select '||v_object_type||'.sws_req_permission(:content_id) from dual';

	-- construct dynamic sql to invoke the sws_req_permission method within the object type package
	-- object types are searchable only if they implement the interface
	execute immediate  v_code  into v_permission using content_id;
                                                           
	return v_permission;                                                           
	exception
	    when others then
		return null;

    end get_content_permission;                                                                        
                                                                                
    function get_content_url (                                                  
	content_id		in sws_search_contents.content_id%TYPE                              
    ) return varchar2                                                           
    is                                                                          
	v_cursor_id		integer;                                                          
	v_link			varchar2(1000);                                                 
      	v_code			varchar2(4000);        
       	v_object_type		acs_object_types.object_type%TYPE;  
        v_result		integer;                                                           
    begin                                                                       
	v_object_type := acs_object_util.get_object_type (                             
	    object_id => content_id                                                    
	);                                                                             

	v_object_type := acs_interface.obj_provide_implement (
	    interface_name	    => 'sws_display',
	    programming_language    => 'pl/sql',
	    object_type		    => v_object_type );

                                                                        
	-- construct dynamic sql to invoke the sws_url method within the object type package
	-- object types are searchable only if they implement the interface
	v_code := 'select '||v_object_type||'.sws_url(:content_id) from dual';
	execute immediate v_code  into v_link using content_id;     
                                                                                
	return v_link;                                                                 
	exception
	    when others then
		return null;

    end get_content_url;                                                                        
                                                                                
    function get_content_title (                                                
	content_id in sws_search_contents.content_id%TYPE                              
    ) return varchar2                                                           
    is                                                                          
	v_cursor_id		integer;                                                          
	v_title			varchar2(1000);   
        v_code			varchar2(4000);                
	v_object_type		acs_object_types.object_type%TYPE;                              
	v_result		integer;                      
    begin                                                                       

	v_object_type := acs_object_util.get_object_type (                             
	    object_id => content_id                                                    
	);                                                                             

	v_object_type := acs_interface.obj_provide_implement (
	    interface_name	    => 'sws_display',
	    programming_language    => 'pl/sql',
	    object_type		    => v_object_type );

        v_code :=  'select '||v_object_type||'.sws_title(:content_id) from dual'; 
                                                              
	-- construct dynamic sql to invoke the sws_title method within the object type package
	-- object types are searchable only if they implement the interface
	execute immediate v_code into v_title using content_id;
                                                                                
	return v_title;                                                                
	exception
	    when others then
		return null;

    end get_content_title;                                                                        
                                                                                
    function get_content_summary (                                              
	content_id in sws_search_contents.content_id%TYPE                              
    ) return varchar2                                                           
    is                                                                          
	v_cursor_id		integer;                                                          
	v_summary		varchar2(4000);							
	v_code			varchar2(4000); 
	v_object_type		acs_object_types.object_type%TYPE;                              
	v_result		integer;                                        
                     
    begin                                                                       
                                                                                
	v_object_type := acs_object_util.get_object_type (                             
	    object_id => content_id                                                    
	);                                                                             

	v_object_type := acs_interface.obj_provide_implement (
	    interface_name	    => 'sws_display',
	    programming_language    => 'pl/sql',
	    object_type		    => v_object_type );

        v_code := 'select '||v_object_type||'.sws_summary(:content_id)  from dual';

	-- construct dynamic sql to invoke the sws_content_summary method within the object type package
	-- object types are searchable only if they implement the interface
	execute immediate v_code  into v_summary using content_id;
                                                                                
	return v_summary;                                                              
	exception
	    when others then
		return null;

    end get_content_summary;                                                                        


    -- wrapper function for 'sws_indexing' interface method
    procedure content_sws_index_proc (                                          
	content_id  in sws_search_contents.content_id%TYPE,                            
	bdata	    in out nocopy blob                                                   
    )                                                                           
    is                                                                          
	v_cursor_id		integer;                                                          
	v_code			varchar2(4000);                                                
	v_object_type		acs_object_types.object_type%TYPE;                              
	v_implement_p		char(1);                                                        
	v_result		integer;
	v_bdata			blob; 
	v_size			integer;
    begin                                                                       

	v_object_type := acs_object_util.get_object_type (                         
			    object_id => content_id                                                       
			 );                                                                         

	v_object_type := acs_interface.obj_provide_implement (
	    interface_name	    => 'sws_indexing',
	    programming_language    => 'pl/sql',
	    object_type		    => v_object_type );

	v_code := 'begin '||v_object_type||'.sws_index_proc( :content_id, :bdata ); end;';

	execute immediate v_code using content_id, in out bdata;
    end content_sws_index_proc;                                                                        

                       
    -- the procedure that is called by teh                                                          
    procedure sws_index_proc(
	rid			in rowid,          
        bdata			in out nocopy blob                            
    )                                                                           
    is                                                                          
	v_imp_sws_display_p	char(1);                                                 
	v_content_id		sws_search_contents.content_id%TYPE; 
	v_bdata			blob;
	v_content_length	integer;
    begin                                                                       

	select content_id into v_content_id                                            
	from sws_search_contents                                                       
	where rowid = rid;                                                             

	v_imp_sws_display_p := acs_interface.object_id_implement_p (                   
	    interface_name	    => 'sws_indexing'   ,                                          
	    programming_language    => 'pl/sql'		,                                                      
	    object_id		    => v_content_id                                                  
	);                                                                             
                                                   
	-- if an object is an instance of an object type that supports the indexing interface,
	-- call the object interface procedure                                         
	if v_imp_sws_display_p = 't' then                                              
	    dbms_lob.trim(bdata,0);
	    sws_service.content_sws_index_proc (                                       
		v_content_id,                                                   
		bdata                                                                
	    );                                                                         
	else                                                                           
	-- else just get the content directly from acs_contents                        
	    dbms_lob.trim(bdata,0);

	    select content,
		   dbms_lob.getlength(content) 
	    into   v_bdata, 
		   v_content_length                                                  
	    from acs_contents
	    where content_id = v_content_id;

	    if v_content_length > 0 then
		dbms_lob.copy  (
		    dest_lob	    => bdata	,
		    src_lob	    => v_bdata	,
		    amount	    => v_content_length
		);
	    end if;
	end if;                                                                        
    end sws_index_proc; 
                                                                                
    -- function to update the application_id, node_id, 
    -- and permission for an object
    procedure update_content_info (                                             
	content_id		in sws_search_contents.content_id%TYPE                             
    )                                                                           
    is                                                                          
	v_imp_interface_p	char(1);                                                     
	v_node_id		sws_search_contents.node_id%TYPE;                                  
	v_application_id	sws_search_contents.application_id%TYPE;                      
	v_permission		sws_search_contents.permission_req%TYPE;                         
	v_code			varchar2(4000);                                                   
	v_cursor_id		integer;                                                          
    begin                                                                       
                                                                                
	-- check that object id is an object type that implements that interface       
	v_imp_interface_p := acs_interface.object_id_implement_p (                     
	    interface_name	    => 'sws_display',                                           
	    programming_language    => 'pl/sql',                                                      
	    object_id		    =>  content_id                                                   
	);                                                                             
                                                                                
	if v_imp_interface_p = 'f' then                                                
	    return;                                                                    
	end if;                                                                        

	-- call the wrapper functions to populate the table
	-- node_id, application_id, and permissions
	v_node_id := sws_service.get_content_node_id (                                  
	    content_id => content_id                                                   
	);                                                                             
                                                                                
	v_application_id := sws_service.get_content_application_id (                      
	    content_id => content_id                                                   
	);                                                                             
                                                                                
	v_permission := sws_service.get_content_permission(                            
	    content_id => content_id                                                   
	);                                                                             
        
	-- update the content display information  
	update sws_search_contents                                                     
	set node_id = v_node_id			,                                                       
	    application_id = v_application_id	,                                         
	    permission_req = v_permission       ,
	    data_store = 'a'                                             
	where content_id = sws_service.update_content_info.content_id;                                                 
    end update_content_info;                                                    

    procedure update_content_obj_type_info (
	object_type in acs_object_types.object_type%TYPE
    ) 
    is
    begin
	update sws_search_contents
        set    data_store = 'a'
        where  acs_object_util.get_object_type(content_id) = object_type;
    end update_content_obj_type_info;  

    -- procedure that rebuilds the site wide search index
    procedure rebuild_index                                                   
    is                                                                          
	v_code			    varchar2(4000);		
	v_cursor_id		    integer;
	v_result		    integer;
    begin

	-- The rows that were updated, we compute the application, permission, and subsite info
	for content_row in (
	    select content_id 
	    from sws_search_contents ssc, 
	    ctxsys.ctx_user_pending cup
	    where ssc.rowid = cup.pnd_rowid) loop 
	    
	    sws_service.update_content_info(content_row.content_id);
	end loop;

	-- construct dynamic sql to build index
	v_cursor_id := dbms_sql.open_cursor;
	v_code := 'alter index sws_srch_cts_ds_iidx rebuild online parameters (''sync'')';
	dbms_sql.parse (v_cursor_id, v_code, dbms_sql.native);                     
	v_result := dbms_sql.execute (v_cursor_id);
	dbms_sql.close_cursor(v_cursor_id);
    end rebuild_index;                                                                        
                                                                                

    procedure rebuild_all_index
    is 
    begin
	-- mark all data for reindexing
	-- by updating the data_store column to 'a'  
	update sws_search_contents
	set data_store = 'a';

	sws_service.rebuild_index;
    end;

                                                                                
    -- given an object id, function returns its context object whose type is object type 
    function first_obj_type_in_context_tree (                                            
	object_id		    in acs_objects.object_id%TYPE,                                       
	object_type		    in acs_object_types.object_type%TYPE                               
    ) return acs_objects.object_id%TYPE                                         
    is                                                                          
	v_object_id	    integer;                                                       
	v_object_type_p	    char(1);                                                   
	cursor v_cursor is                                                             
	    select object_id                                                           
	    from acs_objects                                                           
	    start with object_id = sws_service.first_obj_type_in_context_tree.object_id         
	    connect by prior context_id = object_id;                                   
	v_cursor_row	    v_cursor%ROWTYPE;                                             
    begin                                                                       
	open v_cursor;                                                                 
	fetch v_cursor into v_cursor_row;                                              

	-- traverse up the context hierarchy and find first object whose
	-- type is the desired object type.
  	while v_cursor%found loop                                                      
                                                                                
	    v_object_type_p := acs_object_util.object_type_p (                         
		object_id	=> v_cursor_row.object_id,                                 
		object_type	=> sws_service.first_obj_type_in_context_tree.object_type                  
	    );                                                                         
                                                                                
	    if v_object_type_p = 't' then                                              
		return v_cursor_row.object_id;                                                
	    end if;                                                                    
	    fetch v_cursor into v_cursor_row;                                          
	end loop;                                                                      
                                                                                
	return null;                                                                   
    end first_obj_type_in_context_tree;
                                                                        
end sws_service; 
/









