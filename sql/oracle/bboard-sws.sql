-- This package is to support acs_message_revision types
-- After running this package, place the search-redirect.tcl
-- in the bboard www directory.  search-redirect.tcl takes
-- the message id and finds out the first forum that messsage belongs.

create or replace package acs_message_revision__sws
is
    function sws_title (
	object_id		in acs_objects.object_id%type
    ) return varchar2;

    function sws_url (
	object_id           in acs_objects.object_id%type
    ) return varchar2;

    function sws_summary (
	object_id		in acs_objects.object_id%type
    ) return varchar2;    

    function sws_req_permission (
	object_id		in acs_objects.object_id%type
    ) return varchar2;

    function sws_site_node_id (
	object_id           in acs_objects.object_id%type
    ) return site_nodes.node_id%TYPE;

    function sws_application_id (
	object_id	    in acs_objects.object_id%type
    ) return apm_packages.package_id%TYPE;

    procedure sws_index_proc (
	object_id	    in acs_objects.object_id%type,
	bdata		in out nocopy BLOB
    );
end acs_message_revision__sws;
/

create or replace package body acs_message_revision__sws 
is
    function sws_title (
	object_id		in acs_objects.object_id%type
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
	object_id           in acs_objects.object_id%type
    ) return varchar2
    is 
        url                     varchar2(3000);     
	v_item_id			number;
    begin 
        url := sws_service_interface.sws_url (
               object_id            => object_id 
        );

	select item_id into v_item_id
	from cr_revisions
	where revision_id = object_id;

        return url||to_char(v_item_id);
    end sws_url;

    function sws_summary (
	object_id		in acs_objects.object_id%type
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
	object_id		in acs_objects.object_id%type
    ) return varchar2 
    is
    begin
	return null;
    end;

    function sws_site_node_id (
	object_id           in acs_objects.object_id%type
    ) return site_nodes.node_id%TYPE
    is
        node_id             site_nodes.node_id%type;
    begin
        node_id := sws_service_interface.sws_site_node_id (
                        object_id           => object_id
                   );
        return node_id;         
    end;


    function sws_application_id (
	object_id	    in acs_objects.object_id%type
    ) return apm_packages.package_id%TYPE
    is
        v_application_id        apm_packages.package_id%type;
    begin
        v_application_id := sws_service_interface.sws_application_id (
                                object_id       => object_id
                            );
        return v_application_id;
    end;

    procedure sws_index_proc (
	object_id	    in acs_objects.object_id%type,
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
end acs_message_revision__sws;
/

begin
  acs_interface.assoc_obj_type_with_interface (
	    interface_name          => 'sws_display' ,
	    programming_language    => 'pl/sql'      ,
	    object_type             => 'acs_message_revision',
	    object_type_imp	    => 'acs_message_revision__sws'  
       );

  acs_interface.assoc_obj_type_with_interface (
	    interface_name          => 'sws_indexing' ,
	    programming_language    => 'pl/sql'      ,
	    object_type             => 'acs_message_revision',
	    object_type_imp	    => 'acs_message_revision__sws' 
       );
end;
/


begin
    pot_service.register_object_type (
	package_key		=> 'bboard',
	object_type		=> 'acs_message_revision'
    );

    pot_service.set_obj_type_attr_value (
	package_key		=> 'bboard',
	object_type		=> 'acs_message_revision',
	attribute		=> 'display_page',
	attribute_value		=> 'search-redirect?message_id='
    );    

    sws_service.update_content_obj_type_info ('acs_message_revision');
    sws_service.rebuild_index;
end;
/


