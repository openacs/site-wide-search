
create or replace function fs_root_folder_p (
    folder_id    in fs_root_folders.folder_id%TYPE
) 
return integer
is
    v_folder_p     integer;
begin
    select count(1)
    into v_folder_p
    from fs_root_folders
    where folder_id = fs_root_folder_p.folder_id;       
 
    return v_folder_p;
end fs_root_folder_p;
/

-- function returns the file storage package id that 
-- contains the revision (if any).

create or replace function fs_cr_revision_in_package_id (
     revision_id    in   cr_revisions.revision_id%TYPE
) return apm_packages.package_id%TYPE
is
    v_package_id     apm_packages.package_id%TYPE;
    v_item_id        cr_items.item_id%TYPE;
begin

    select item_id into v_item_id 
    from cr_revisions 
    where revision_id = fs_cr_revision_in_package_id.revision_id;

    v_package_id := null;

    -- Expect one row, if no row then v_package_id stays null
    -- select thru all the cr_item tree and mark the folder, row_count = 1 , 
    -- if the item_id is in cr_root_folder. 
    for row_info in (
                       select cr.parent_id    , 
                              cr.item_id      , 
                              fs_root_folder_p(cr.item_id) as folder_root_p
                       from cr_items cr
                       start with item_id = fs_cr_revision_in_package_id.v_item_id
                       connect by item_id = prior parent_id
                       order by folder_root_p desc) loop
        
        -- the list are sorted by folder_root_p in desc.
        -- Only one root folder per fs, thus if the content item is contained
        --   within a fs root folder, then cr_item is the folder_id)
        if row_info.folder_root_p > 0 then

            select package_id 
            into   v_package_id
            from   fs_root_folders
            where  folder_id = row_info.item_id;

           return v_package_id;
        end if;

        return null;
    end loop;

    return v_package_id;

    exception 
        when no_data_found then
            return null;
end fs_cr_revision_in_package_id;
/


begin
    pot_service.register_object_type (
	package_key		=> 'file-storage',
	object_type		=> 'content_revision'
    );

    pot_service.set_obj_type_attr_value (
	package_key		=> 'file-storage',
	object_type		=> 'content_revision',
	attribute		=> 'display_page',
	attribute_value		=> 'file?file_id='
    );    

    pot_service.set_obj_type_attr_value (
	package_key		=> 'file-storage',
	object_type		=> 'content_revision',
	attribute		=> 'cr_revision_in_package_id',
	attribute_value		=> 'fs_cr_revision_in_package_id'
    );    

    sws_service.update_content_obj_type_info ('content_revision');
end;
/




