begin

    acs_interface.remove_obj_type_impl (
	    interface_name          => 'sws_display' ,
	    programming_language    => 'pl/sql'      ,
	    object_type             => 'content_revision'
    );

    acs_interface.remove_obj_type_impl (
	    interface_name          => 'sws_indexing' ,
	    programming_language    => 'pl/sql'      ,
	    object_type             => 'content_revision'
    );	

    pot_service.drop_attribute (
            attribute               => 'cr_revision_in_package_id'   
    );
end;
/

drop package content_revision__sws;