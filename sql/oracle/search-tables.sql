--
-- packages/site-wide-search/sql/search-tables.sql
-- 
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
-- 

create table sws_search_contents (
    content_id		integer
	constraint sws_search_content_id_pk primary key
	constraint sws_search_content_id_fk references acs_contents(content_id) on delete cascade,
    -- application that owns this content
    application_id	integer
	constraint sws_search_appl_id_fk references apm_applications on delete cascade,
    node_id		integer
	constraint sws_search_node_id_fk references site_nodes on delete cascade,
    permission_req	varchar2(100),
    data_store		char(1) 
);

comment on table sws_search_contents is 'Store rows from acs_contents that should be indexed. Table is 
    populated/modified by three triggers, on acs_contents,  based on the searchable_p state change. 
    Insert when:  
	1. insert into acs_contents and searchble_p is true 
	2. update searchable_p from false to true.
    Update when:
        1. update other columns besides searchable_p, when searchable_p stays true
    Delete as follows:
        1. Delete acs_contents row
        2. update searchable_p from true to false.
    Note: the application_id, node_id, and permission_req are populated when on insert and update conditions. 
';

comment on column sws_search_contents.application_id is 'The application_id that is handling the object.';

comment on column sws_search_contents.node_id is 'The site node where the object display page resides';

comment on column sws_search_contents.permission_req is 'The permission needed for search to 
    display content in the search result. If null, then no permission is checked.';


-- Package contains:
--   1. Wrapper functions to handle the 'sws_display' and 'sws_indexing' interface method calls.
--      a. 'sws_display' interface defines methods to retrieving display and site node from each object type
--      b. 'sws_indexing' method for object types to specify their own content to index instead
--	    of the content in acs_contents table. 
--   2. Rebuild index function. 
--   3. Function to walk up context tree and returns the first object of a specified type.
create or replace package sws_service
as                                                                              
                                 
    -- the first 6 are wrapper functions for the 'sws_display' interface methods
    function get_content_node_id (                                                 
	content_id in sws_search_contents.content_id%TYPE                              
    ) return sws_search_contents.node_id%TYPE;                                  

    function get_content_application_id (                                          
	content_id in sws_search_contents.content_id%TYPE                              
    ) return sws_search_contents.application_id%TYPE;                           
                                                                                
    function get_content_permission (                                           
	content_id in sws_search_contents.content_id%TYPE                              
    ) return sws_search_contents.permission_req%TYPE;                           
                                                                                
    function get_content_url (                                                  
	content_id in sws_search_contents.content_id%TYPE                              
    ) return varchar2;                                                          
                                                                                
    function get_content_title (                                                
	content_id in sws_search_contents.content_id%TYPE                              
    ) return varchar2;                                                          
                                                                                
    function get_content_summary (                                              
	content_id in sws_search_contents.content_id%TYPE                              
    ) return varchar2;                                                          

    procedure content_sws_index_proc (                                          
	content_id  in sws_search_contents.content_id%TYPE,                            
	bdata	    in out nocopy blob                                                   
    );


    -- wrapper function for 'sws_indexing' interface method
    procedure sws_index_proc (                                                  
	rid	    in rowid,                                                              
	bdata	    in out nocopy blob                                                   
    );                                                                          

    -- procedure updates the application_id, node_id, 
    -- and permission for an object
    procedure update_content_info (                                             
	content_id in sws_search_contents.content_id%TYPE                              
    );                       
                                                   
    -- procedure updates the application_id, node_id,
    -- and permission for all object types
    procedure update_content_obj_type_info (
	object_type in acs_object_types.object_type%TYPE
    );

    -- rebuilds index for the content, since the last time index was ran.
    procedure rebuild_index;

    -- reindexes all content      
    procedure rebuild_all_index;

    -- given an object id, function returns its context object whose type is object type 
    function first_obj_type_in_context_tree (                                            
	object_id	in acs_objects.object_id%TYPE,
	object_type	in acs_object_types.object_type%TYPE                               
    ) return acs_objects.object_id%TYPE;                                        


end sws_service;                                                                
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
        -- DRB: use the "online" variant if you have Oracle Enterprise Edition
	-- v_code := 'alter index sws_srch_cts_ds_iidx rebuild online parameters (''sync'')';
	v_code := 'alter index sws_srch_cts_ds_iidx rebuild parameters (''sync'')';
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


-- The 2 triggers that enforce the insert and update
-- delete conditions on sws_search_contents uses delete on cascade

-- if new row is added to acs_contents and searchable_p is true,
-- then add row to sws_search_contents
create or replace trigger acs_contents_sws_itr 
after insert on acs_contents 
for each row
declare
    v_valid_type_p	char(1);
begin

    if :new.searchable_p = 't' then
	insert into sws_search_contents (
	    content_id,
	    data_store
	) values (
	    :new.content_id,
	    'a'
	);
    end if;
end;
/
	
-- if an update was done:
--     change t --> t = update data_store column to 'a', 
--     change t --> f = delete row from sws_search_contents
--     change f --> t = insert row into sws_search_contents
create or replace trigger acs_contents_sws_utr 
after update on acs_contents 
for each row 
declare
begin
    -- if the data is updated, then re-index the content
    if :new.searchable_p = :old.searchable_p 
	and :old.searchable_p = 't' then
	update sws_search_contents
	set data_store = 'a'
	where content_id = :new.content_id;

    elsif :new.searchable_p = 't' then

    -- If previously the content was not ready for searching
    -- now include content for searching.
	insert into sws_search_contents (
	    content_id,
	    data_store
	) values (
	    :new.content_id,
	    'a'
	); 

    else 
	delete from sws_search_contents
	where content_id = :new.content_id;
    end if;
end;
/
	

-- Declaractions for 'sws_display' and 'sws_indexing' interfaces. 
declare 
    v_interface_id		integer;
    v_method_id			integer;
    v_param_id			integer;
begin

    v_interface_id := acs_interface.new (
	interface_name		=> 'sws_display',
	programming_language	=> 'pl/sql',
	enabled_p		=> 't',
	description		=> 'Interface for object types to include in site wide search'
    );


    -- Get the application id for object  --
    v_method_id := acs_interface.add_method (
	interface_name		=> 'sws_display',
	programming_language	=> 'pl/sql',
	method_name		=> 'sws_application_id',
	method_type		=> 'function',
	return_type		=> 'apm_packages.package_id%TYPE',
	method_desc		=> 'returns the application id that owns/maintains object'
    );

    acs_interface.add_param_to_method (
	method_id		=> v_method_id,
	param_name		=> 'object_id',
	param_type		=> 'acs_objects.object_id%TYPE',
	param_desc		=> 'the acs object id'
    );

    v_method_id := acs_interface.add_method (
	interface_name		=> 'sws_display',
	programming_language	=> 'pl/sql',
	method_name		=> 'sws_site_node_id',
	method_type		=> 'function',
	return_type		=> 'site_nodes.node_id%TYPE',
	method_desc		=> 'returns the node id'
    );

    acs_interface.add_param_to_method (
	method_id		=> v_method_id,
	param_name		=> 'object_id',
	param_type		=> 'acs_objects.object_id%TYPE',
	param_desc		=> 'the acs object id'
    );

    v_method_id := acs_interface.add_method (
	interface_name		=> 'sws_display',
	programming_language	=> 'pl/sql',
	method_name		=> 'sws_req_permission',
	method_type		=> 'function',
	return_type		=> 'acs_permissions.privilege%TYPE',
	method_desc		=> 'returns the permission required to display'
    );

    acs_interface.add_param_to_method (
	method_id		=> v_method_id,
	param_name		=> 'object_id',
	param_type		=> 'acs_objects.object_id%TYPE',
	param_desc		=> 'the acs object id'
    );

	
    -- Get link to the object -- 
    v_method_id := acs_interface.add_method (
	interface_name		=> 'sws_display',
	programming_language	=> 'pl/sql',
	method_name		=> 'sws_url',
	method_type		=> 'function',
	return_type		=> 'varchar2(4000)',
	method_desc		=> 'returns the link to the object id'
    );
    
    acs_interface.add_param_to_method (
	method_id		=> v_method_id,
	param_name		=> 'object_id',
	param_type		=> 'acs_objects.object_id%TYPE',
	param_desc		=> 'the acs object id'
    );

    -- Get title for the object --
    v_method_id := acs_interface.add_method (
	interface_name		=> 'sws_display',
	programming_language	=> 'pl/sql',
	method_name		=> 'sws_title',
	method_type		=> 'function',
	return_type		=> 'varchar2(2000)',
	method_desc		=> 'returns the title for the object'
    );
    
    acs_interface.add_param_to_method (
	method_id		=> v_method_id,
	param_name		=> 'object_id',
	param_type		=> 'acs_objects.object_id%TYPE',
	param_desc		=> 'the acs object id'
    );

    -- Get summary for the object -- 
    v_method_id := acs_interface.add_method (
	interface_name		=> 'sws_display',
	programming_language	=> 'pl/sql',
	method_name		=> 'sws_summary',
	method_type		=> 'function',
	return_type		=> 'varchar2(4000)',
	method_desc		=> 'returns the summary for the object'
    );
    
    acs_interface.add_param_to_method (
	method_id		=> v_method_id,
	param_name		=> 'object_id',
	param_type		=> 'acs_objects.object_id%TYPE',
	param_desc		=> 'the acs object id'
    );


    -- Setup the interface for the site wide index. Object types may define 
    -- their own procedures for building data to be indexed  
    v_interface_id := acs_interface.new (
	interface_name		=> 'sws_indexing',
	programming_language	=> 'pl/sql',
	enabled_p		=> 't',
	description		=> 'Procedures to get object content to get indexed'
    );

    -- add procedure to, not used currently
    v_method_id := acs_interface.add_method (
	interface_name		=> 'sws_indexing',
	programming_language	=> 'pl/sql',
	method_name		=> 'sws_index_proc',
	method_type		=> 'procedure',
	return_type		=> '',
	method_desc		=> 'procedure that builds the data to be indexed'
    );    	

    acs_interface.add_param_to_method (
	method_id		=> v_method_id,
	param_name		=> 'object_id',
	param_type		=> 'acs_objects.object_id%TYPE',
	param_desc		=> 'the object to be indexed'
    );

    acs_interface.add_param_to_method (
	method_id		=> v_method_id,
	param_name		=> 'bdata',
	param_type		=> 'blob',
	param_desc		=> 'the data to be indexed',
	param_ref_p		=> 't',
	param_spec		=> 'nocopy'
    );
end;
/    
