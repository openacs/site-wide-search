begin
    acs_interface.remove_obj_type_impl (
	    interface_name          => 'sws_display' ,
	    programming_language    => 'pl/sql'      ,
	    object_type             => 'acs_message_revision'
    );

    acs_interface.remove_obj_type_impl (
	    interface_name          => 'sws_indexing' ,
	    programming_language    => 'pl/sql'      ,
	    object_type             => 'acs_message_revision'
    );	
end;
/

drop package acs_message_revision__sws;

begin
    pot_service.delete_obj_type_attr_value (
	    package_key		    => 'bboard'	,
	    object_type		    => 'acs_message_revision'	,
	    attribute		    => 'display_page'
    );

    pot_service.unregister_object_type (
	    package_key		    => 'bboard'	,
	    object_type		    => 'acs_message_revision'
    );
end;
/

















