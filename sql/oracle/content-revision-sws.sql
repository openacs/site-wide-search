-- 
-- packages/acs-interfaces/sql/content-revision-sws.sql
--
-- @author khy@arsdigita.com
-- @creation-date 2001-01-17
-- @cvs-id $Id$
--

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

begin

  acs_interface.assoc_obj_type_with_interface (
	    interface_name          => 'sws_display' ,
	    programming_language    => 'pl/sql'      ,
	    object_type             => 'content_revision',
	    object_type_imp	    => 'content_revision__sws'  
       );

  acs_interface.assoc_obj_type_with_interface (
	    interface_name          => 'sws_indexing' ,
	    programming_language    => 'pl/sql'      ,
	    object_type             => 'content_revision',
	    object_type_imp	    => 'content_revision__sws' 
       );

--  Add to support different applications 
    pot_service.create_attribute (
        attribute       => 'cr_revision_in_package_id',
        description     => 'Used by content revision object to ask applications whether they 
                            are one of the owners of the content revision item. This method takes
                            one parameter, revision_id, and returns the package instance id that "owns" it.'
    );

    sws_service.update_content_obj_type_info ('content_revision');
end;
/
