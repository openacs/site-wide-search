-- pot --> Package Object Type Attributes 
-- 
--
-- packages/site-wide-search/pot.sql
--
-- @author khy@arsdigita.com
-- @creation-data 2000-12-01
-- @cvs-id $Id$
--


set feedback off

-- Purpose: 
--    1. Define system wide attributes for object types
--    2. Specify default object type attribute values. 
--    3. Specify object type attribute values for a package.
--           
--    Currently there is only one system wide attribute, display_page.  This attribute
--    specifies the page pattern (*?*=) that displays an instance of an object type.  
--    Services could refer to another package to display package specific information about the object. 

create table pot_map (
    package_key		varchar2(100)
	constraint pot_map_package_key_fk references apm_package_types(package_key) on delete cascade,
    object_type		varchar2(100)
	constraint pot_map_object_type_fk references acs_object_types(object_type) on delete cascade,
    constraint pot_map_pkg_key_obj_type_pk primary key (package_key, object_type)
);

comment on table pot_map is 'Manages object types used by a package.  Packages should 
    register their object types and any optional attributes values to each object type.';

comment on column pot_map.package_key is 'This is at the package type level, not the 
    package instance.'

create table pot_attributes (
    attribute		varchar2(100)
	constraint pota_attribute_pk primary key,
    description		varchar2(4000)
);

comment on table pot_attributes is 'Definition of optional system attributes';


create table pot_obj_type_attr_values (
    object_type		varchar2(100)
	constraint pot_otav_obj_type_fk references acs_object_types (object_type) on delete cascade,
    attribute		varchar2(100)
	constraint pot_otav_attribute_fk references pot_attributes(attribute) on delete cascade,
    attribute_value	varchar2(4000)
	constraint pot_otav_attr_value_nn not null,
    constraint pot_otav_attribute_value_pk primary key (object_type, attribute)
);

comment on table pot_obj_type_attr_values is 'The default attribute values for each object type';

create table pot_map_attr_values (
    package_key		varchar2(100)
	constraint pot_matv_package_key_fk references apm_package_types(package_key) on delete cascade
	constraint pot_matv_package_key_nn not null,
    object_type		varchar2(100)
	constraint pot_matv_object_type_fk references acs_object_types(object_type) on delete cascade
	constraint pot_matv_object_type_nn not null,
    attribute		varchar2(100)
	constraint pot_matv_attribute_fk references pot_attributes (attribute) on delete cascade,
    attribute_value	varchar2(4000) 
	constraint pot_matv_attr_value_nn not null,
    constraint          pot_matv_pkg_obj_type_fk foreign key (package_key, object_type)
						 references pot_map(package_key, object_type),
    constraint          pot_matv_pkg_obj_type_attr_pk primary key (package_key, object_type, attribute)
);

comment on table pot_map_attr_values is 'The package''s object type attribute values';


-- Package to add/delete attributes, specify default object type attributes values, and 
-- package object type attribute values. 
create or replace package pot_service
as 

    procedure register_object_type (
	package_key		in pot_map.package_key%TYPE,
	object_type		in pot_map.object_type%TYPE
    );

    procedure unregister_object_type (
	package_key		in pot_map.package_key%TYPE,
	object_type		in pot_map.object_type%TYPE
    );

    procedure create_attribute (
	attribute		in pot_attributes.attribute%TYPE,
	description		in pot_attributes.description%TYPE
    );
    procedure drop_attribute (
	attribute		in pot_attributes.attribute%TYPE
    ); 
    procedure set_default_attr_value (
	object_type		in pot_map.object_type%TYPE	    ,
	attribute		in pot_attributes.attribute%TYPE    ,
	attribute_value		in pot_obj_type_attr_values.attribute_value%TYPE
    );
    procedure delete_default_attr_value (
	object_type		in pot_map.object_type%TYPE,
	attribute		in pot_attributes.attribute%TYPE
    );
    function get_default_attr_value (
	object_type		in pot_map.object_type%TYPE,
	attribute		in pot_attributes.attribute%TYPE
    ) return pot_obj_type_attr_values.attribute_value%TYPE;	

    procedure set_obj_type_attr_value (
	package_key		in pot_map.package_key%TYPE	    ,
	object_type		in pot_map.object_type%TYPE	    ,
	attribute		in pot_attributes.attribute%TYPE    ,
	attribute_value		in pot_obj_type_attr_values.attribute_value%TYPE
    );		
    procedure delete_obj_type_attr_value (
	package_key		in pot_map.package_key%TYPE	,
	object_type		in pot_map.object_type%TYPE	,
	attribute		in pot_attributes.attribute%TYPE
    );
    function get_obj_type_attr_value (
	package_key		in pot_map.package_key%TYPE	,
	object_type		in pot_map.object_type%TYPE	,
	attribute		in pot_attributes.attribute%TYPE
    ) return pot_map_attr_values.attribute_value%TYPE;
end pot_service;
/


create or replace package body pot_service
is
    procedure register_object_type (
	package_key		in pot_map.package_key%TYPE,
	object_type		in pot_map.object_type%TYPE
    ) 
    is
    begin
	insert into pot_map (
	    package_key,
	    object_type 
	) values (
	    package_key,
	    object_type
	);
    end register_object_type;

    procedure unregister_object_type (
	package_key		in pot_map.package_key%TYPE,
	object_type		in pot_map.object_type%TYPE
    )
    is
    begin
	delete from pot_map
	where package_key = pot_service.unregister_object_type.package_key
	and   object_type = pot_service.unregister_object_type.object_type;
    end unregister_object_type;

    procedure create_attribute (
	attribute		in pot_attributes.attribute%TYPE,
	description		in pot_attributes.description%TYPE
    ) 
    is
    begin
	insert into pot_attributes (
	    attribute,
	    description
	) values (
	    attribute,
	    description
	);
    end create_attribute;

    procedure drop_attribute (
	attribute		in pot_attributes.attribute%TYPE
    )
    is
    begin
	delete from pot_attributes
	where attribute = pot_service.drop_attribute.attribute;
    end drop_attribute;
	 
    procedure set_default_attr_value (
	object_type		in pot_map.object_type%TYPE	    ,
	attribute		in pot_attributes.attribute%TYPE    ,
	attribute_value		in pot_obj_type_attr_values.attribute_value%TYPE
    )
    is
	exist_p			char(1);
    begin
	
	-- check if a default values exist 
	select decode(count(*),0,'f','t') into exist_p
	from pot_obj_type_attr_values
	where object_type = pot_service.set_default_attr_value.object_type;

	-- if no default value row exist, then insert 
	if exist_p = 'f' then
	    insert into pot_obj_type_attr_values (
		object_type,
		attribute,
		attribute_value
	    ) values (
		pot_service.set_default_attr_value.object_type	,
		pot_service.set_default_attr_value.attribute	,
		pot_service.set_default_attr_value.attribute_value
	    );
	else 
	-- if a default value row exists, then update 
	    update pot_obj_type_attr_values
	    set attribute_value = pot_service.set_default_attr_value.attribute_value
	    where object_type = pot_service.set_default_attr_value.object_type
	    and   attribute = pot_service.set_default_attr_value.attribute;
	end if;
    end set_default_attr_value;

    procedure delete_default_attr_value (
	object_type		in pot_map.object_type%TYPE,
	attribute		in pot_attributes.attribute%TYPE
    )
    is
    begin
	delete from pot_obj_type_attr_values
	where object_type = pot_service.delete_default_attr_value.object_type
	and   attribute = pot_service.delete_default_attr_value.attribute;
    end delete_default_attr_value;

    function get_default_attr_value (
	object_type		in pot_map.object_type%TYPE,
	attribute		in pot_attributes.attribute%TYPE
    ) return pot_obj_type_attr_values.attribute_value%TYPE
    is
	v_attribute_value	pot_obj_type_attr_values.attribute_value%TYPE;
    begin
	
	-- retrieve the default value for the attribute
	select attribute_value into v_attribute_value
	from pot_obj_type_attr_values
	where object_type = pot_service.get_default_attr_value.object_type
	and   attribute = pot_service.get_default_attr_value.attribute;

	return v_attribute_value;
    
	exception 
	    when  no_data_found then
		return null; 
    end get_default_attr_value;

    procedure set_obj_type_attr_value (
	package_key		in pot_map.package_key%TYPE	    ,
	object_type		in pot_map.object_type%TYPE	    ,
	attribute		in pot_attributes.attribute%TYPE    ,
	attribute_value		in pot_obj_type_attr_values.attribute_value%TYPE
    ) 
    is
	exist_p			char(1);
    begin 

	select decode(count(*),0,'f','t') into exist_p
	from pot_map_attr_values
	where package_key = pot_service.set_obj_type_attr_value.package_key
	and object_type = pot_service.set_obj_type_attr_value.object_type 
	and attribute = pot_service.set_obj_type_attr_value.attribute;

	if exist_p = 'f' then
	    insert into pot_map_attr_values (
		object_type,
		package_key,
		attribute,
		attribute_value
	    ) values (
		object_type,
		package_key,
		attribute,
		attribute_value
	    );
	else 
	    update pot_map_attr_values
	    set attribute_value = pot_service.set_obj_type_attr_value.attribute_value
	    where object_type = pot_service.set_obj_type_attr_value.object_type
	    and   package_key = pot_service.set_obj_type_attr_value.package_key
	    and   attribute   = pot_service.set_obj_type_attr_value.attribute;
	end if;

    end set_obj_type_attr_value;
		
    procedure delete_obj_type_attr_value (
	package_key		in pot_map.package_key%TYPE	,
	object_type		in pot_map.object_type%TYPE	,
	attribute		in pot_attributes.attribute%TYPE
    )
    is
    begin
	delete from pot_map_attr_values
	where package_key = pot_service.delete_obj_type_attr_value.package_key
	and   object_type = pot_service.delete_obj_type_attr_value.object_type
	and   attribute   = pot_service.delete_obj_type_attr_value.attribute;
    end delete_obj_type_attr_value;

    function get_obj_type_attr_value (
	package_key		in pot_map.package_key%TYPE	,
	object_type		in pot_map.object_type%TYPE	,
	attribute		in pot_attributes.attribute%TYPE
    ) return pot_map_attr_values.attribute_value%TYPE
    is
	v_attribute_value	pot_map_attr_values.attribute_value%TYPE;
    begin
	select attribute_value into v_attribute_value
	from pot_map_attr_values
	where package_key = pot_service.get_obj_type_attr_value.package_key
	and   object_type = pot_service.get_obj_type_attr_value.object_type
	and   attribute = pot_service.get_obj_type_attr_value.attribute;

	return v_attribute_value;
    
	exception 
	    when  no_data_found then
		return null; 
    end get_obj_type_attr_value;
end pot_service;
/
show errors

begin
    insert into pot_attributes (
	 attribute,
	 description
    ) values (
	 'display_page',
	 'page to display object'
    );
end;
/















