--
-- packages/site-wide-search/sql/sws-service-interface.sql
-- 
-- @author khy@arsdigita.com
-- @creation-date 2000-12-01
-- @cvs-id $Id$
-- 

-- Set of methods to get information about arbitrary objects
-- using the information from Package object type attributes tables
 
create or replace package sws_service_interface
is
    -- Walks up the context tree to find the first 
    -- application that created this object within its context. 
    function sws_application_id (
	object_id		acs_objects.object_id%TYPE
    ) return apm_packages.package_id%TYPE;
    
    -- Returns the first site node of the application that
    -- created this object within its context.
    function sws_site_node_id (
	object_id		acs_objects.object_id%TYPE
    ) return site_nodes.node_id%TYPE;

    -- Returns the site_node url and url pattern registered under the pot_map_attributes table
    -- for the object.
    function sws_url (
	object_id		acs_objects.object_id%TYPE
    ) return varchar;
end sws_service_interface;
/

create or replace package body sws_service_interface
is

    -- Walks up the context tree to find the first 
    -- application that created this object within its context. 
    function sws_application_id (
	object_id		acs_objects.object_id%TYPE
    ) return apm_packages.package_id%TYPE
    is
	v_package_id		apm_packages.package_id%TYPE;
	v_valid_p		char(1);
    begin

	v_package_id := sws_service.first_obj_type_in_context_tree (
	    object_id		=> object_id,
	    object_type		=> 'apm_package'
	);

	select decode(v_package_id, null, 0, 1) into v_valid_p
	from dual;

	if v_valid_p = 0 then
	    return null;	    	    
	end if;
	
	return v_package_id;
    end sws_application_id;
    
    -- Returns the first site node of the application that
    -- created this object within its context.
    function sws_site_node_id (
	object_id		acs_objects.object_id%TYPE
    ) return site_nodes.node_id%TYPE
    is
	v_package_id		apm_packages.package_id%TYPE;
	TYPE t_ref_cusor	is ref cursor;
	v_cursor		t_ref_cusor;
	v_node_id		site_nodes.node_id%TYPE;
    begin
	
	v_package_id := sws_service_interface.sws_application_id(
	    object_id		=> object_id
	);

	if v_package_id = null then
	    return null;
	end if;

	open v_cursor for
	    select node_id
	    from site_nodes
	    where object_id = v_package_id;

	loop
	    fetch v_cursor into v_node_id;
	    
	    exit when v_cursor%notfound;

	    close v_cursor;
	    return v_node_id;

	end loop;

	close v_cursor;
	return null;
    end sws_site_node_id;

    -- Returns the site_node url and url pattern registered under the pot_map_attributes table
    -- for the object.
    function sws_url (
	object_id		acs_objects.object_id%TYPE
    ) return varchar
    is
	v_node_id		site_nodes.node_id%TYPE;
	v_display_page		varchar2(500);
	v_package_key		apm_packages.package_key%TYPE;
    begin

	v_node_id := sws_service_interface.sws_site_node_id (
	    object_id		=> object_id
	);

	if v_node_id is null then
	    return null;
	end if;
	  
	-- get the package key
	select package_key into v_package_key
	from apm_packages 
	where package_id = sws_service_interface.sws_application_id (object_id);

	-- get the object name
	v_display_page := pot_service.get_obj_type_attr_value (
	    package_key		=> v_package_key,
	    object_type		=> acs_object_util.get_object_type(object_id),
	    attribute		=> 'display_page'
	);

	-- if application did not specify page to display the object
	-- we take the default page for the object type
	if v_display_page = null then
	    v_display_page := pot_service.get_default_attr_value (
		object_type	=> acs_object_util.get_object_type(object_id),
		attribute	=> 'display'
	    );

	    if v_display_page = null then
		return null;
	    end if;
	end if;

	return site_node.url(node_id => v_node_id) ||  v_display_page;
    end sws_url;	

end sws_service_interface;
/


















