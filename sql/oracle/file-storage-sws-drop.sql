begin

    pot_service.delete_obj_type_attr_value (
	    package_key		    => 'file-storage'	,
	    object_type		    => 'content_revision'	,
	    attribute		    => 'display_page'
    );

    pot_service.delete_obj_type_attr_value (
	    package_key		    => 'file-storage'	,
	    object_type		    => 'content_revision'	,
	    attribute		    => 'cr_revision_in_package_id'
    );

    pot_service.unregister_object_type (
	    package_key		    => 'file-storage'	,
	    object_type		    => 'content_revision'
    );
end;
/

drop function fs_cr_revision_in_package_id;
drop function fs_root_folder_p;

