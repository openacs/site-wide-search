--
-- packages/site-wide-search/sql/intermedia-setup.sql
-- 
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
--

-- -------------- !!!!!!!!!  EXECUTE IN CTXSYS SCHEMA !!!!!!!!!!! --------------------
-- Notes: Run this script only once for a database, not per ACS Installation.
--        Errors can be ignore if this is not the first time the script was run 
--        under the ctxsys schema.


create sequence sws_procedures_sequence 
start with 1;

-- Notes: The user must have 'create procedure' permission explicitly in order for 
--        dynamic procedure creation calls to work.  In Oracle procedures and functions,
--        roles are disabled. Also the ctxsys user must have the permission to 
--        create procedures.
    
create table sws_procedures (
    procedure_id		integer 
	constraint sws_proc_proc_id_pk primary key,
    schema			varchar2(30)
	constraint sws_proc_schema_nn not null,
    procedure_name		varchar2(20)
	constraint sws_proc_proc_name_nn not null,
    actual_procedure_name	varchar2(30)
	constraint sws_proc_act_proc_name_nn not null,
    creation_date		date
	constraint sws_creation_date_nn not null,
    constraint sws_proc_schema_proc_name_un unique (schema, procedure_name)
);



comment on table sws_procedures is 'Stores the mapping of an alias procedure name, under a schema, 
    to a ctxsys owned indexing procedure';

comment on column sws_procedures.procedure_name is 'the alias procedure name for the schema.';

comment on column sws_procedures.actual_procedure_name is 'The procedure name owned by ctxsys schema.';

comment on column sws_procedures.schema is 'the schema that uses the alias to reference the
    actual procedure';

declare
    v_exist_p	    char(1);
    v_code	    varchar2(4000);
    v_cursor_id	    integer;
    v_result	    integer;
begin

    select decode (count(*), 0,'f','t') into v_exist_p
    from user_objects 
    where object_name = 'SWS_PROCEDURE'
    and object_type = 'PACKAGE';

    v_code := '
	create or replace package sws_procedure
	is

	    function create_procedure (
		schema		    in sws_procedures.schema%TYPE,
		procedure_name      in sws_procedures.procedure_name%TYPE,
		call_procedure	    in varchar2
	    ) return varchar2;

	    procedure drop_procedure (
		schema		    in sws_procedures.schema%TYPE,
		procedure_name      in sws_procedures.procedure_name%TYPE
	    );

	    function get_actual_procedure (
		schema		    in sws_procedures.schema%TYPE,
		procedure_name	    in sws_procedures.procedure_name%TYPE
	    ) return sws_procedures.actual_procedure_name%TYPE;

	    procedure clean_schema (
		schema		in sws_procedures.schema%type
	    );
	end sws_procedure;';

    if v_exist_p = 'f' then
	v_cursor_id := dbms_sql.open_cursor;
	dbms_sql.parse (v_cursor_id, v_code, dbms_sql.native);
	v_result := dbms_sql.execute(v_cursor_id);
	dbms_sql.close_cursor(v_cursor_id);	
	dbms_output.put_line('created package header');
    end if;
end;
/

create or replace package body sws_procedure
as

    -- returns the actual procedure under the ctxsys schema.
    function create_procedure (
	schema		    in sws_procedures.schema%TYPE,
	procedure_name      in sws_procedures.procedure_name%TYPE,
	call_procedure	    varchar2
    ) return varchar2
    is
	v_create_proc_string	varchar2(4000);
	v_create_proc_name	varchar2(200);
	v_cursor		integer;
	v_execute_result	integer;
	v_procedure_id		integer;
    begin

	-- get the actual name 
	select sws_procedures_sequence.nextval into v_procedure_id
	from dual;

	v_create_proc_name := 'procedure_'||to_char(v_procedure_id);

	-- register the procedure 
	insert into sws_procedures (
	    schema		    ,
	    procedure_id	    ,
	    procedure_name	    ,
	    actual_procedure_name   ,
	    creation_date	    
	) values (
	    schema		    ,
	    v_procedure_id	    ,
	    procedure_name	    ,
	    v_create_proc_name	    ,
	    sysdate
	);


	-- Build string to create procedure which in turn 
	-- calls the passed in call_procedure parameter.
	v_create_proc_string := 'create or replace procedure ' || v_create_proc_name || 
	    ' ( rid IN ROWID, bdata IN OUT nocopy blob ) 
	    is begin 
	    ' || schema || '.' || call_procedure || ' ( rid, bdata); 
	    end;';
		  
	dbms_output.put_line(v_create_proc_string);
	v_cursor := dbms_sql.OPEN_CURSOR;
	dbms_sql.parse(v_cursor, v_create_proc_string, dbms_sql.native);
	v_execute_result := dbms_sql.execute(v_cursor);
	dbms_sql.close_cursor(v_cursor);

	-- Build string to grant schema permission to execute procedure.
	v_create_proc_string := 'grant execute on '||v_create_proc_name  || ' to '|| schema;
	v_cursor := dbms_sql.OPEN_CURSOR;
	dbms_sql.parse(v_cursor, v_create_proc_string, dbms_sql.native);
	v_execute_result := dbms_sql.execute(v_cursor);
	dbms_sql.close_cursor(v_cursor);

	return v_create_proc_name;
    end create_procedure;

    procedure drop_procedure (
	schema		    in sws_procedures.schema%TYPE,
	procedure_name      in sws_procedures.procedure_name%TYPE
    ) 
    is 
	v_actual_proc_name  sws_procedures.actual_procedure_name%TYPE;
	v_drop_procedure    varchar2(4000);
	v_cursor	    integer;
	v_execute_result    integer;
	v_procedure_id	    integer;
    begin

	select actual_procedure_name, 
	       procedure_id 
	into   v_actual_proc_name,
	       v_procedure_id
	from ctxsys.sws_procedures
	where schema		= sws_procedure.drop_procedure.schema
	and   procedure_name	= sws_procedure.drop_procedure.procedure_name;
    	
	-- Build string to drop procedure
	v_drop_procedure := 'drop procedure ' || v_actual_proc_name || '';
	dbms_output.put_line(v_drop_procedure);
	v_cursor := dbms_sql.OPEN_CURSOR;
	dbms_sql.parse(v_cursor, v_drop_procedure, dbms_sql.native);
	v_execute_result := dbms_sql.execute(v_cursor);
	dbms_sql.close_cursor(v_cursor);

	delete from sws_procedures
	where procedure_id = v_procedure_id;

	commit;

    end drop_procedure;

    -- Returns the procedure created in ctxsys schema with
    -- the procedure_name alias under parameter schema. 
    function get_actual_procedure (
	schema		    in sws_procedures.schema%TYPE,
	procedure_name	    in sws_procedures.procedure_name%TYPE
    ) return sws_procedures.actual_procedure_name%TYPE 
    is 
	v_actual_proc_name  sws_procedures.actual_procedure_name%TYPE;
    begin
	select actual_procedure_name into v_actual_proc_name
	from ctxsys.sws_procedures
	where schema		= sws_procedure.get_actual_procedure.schema
	and   procedure_name	= sws_procedure.get_actual_procedure.procedure_name;

	return v_actual_proc_name;	

    exception
	when no_data_found then
	    return null;	
    end get_actual_procedure;

    -- Removes all the schema procedures
    procedure clean_schema (
	schema		in sws_procedures.schema%TYPE
    ) 
    is
	Cursor c_proc_name is
	    select procedure_name
	    from sws_procedures
	    where schema = sws_procedure.clean_schema.schema;
    begin

	for v_pref_rec in c_proc_name loop
	    sws_procedure.drop_procedure(schema, v_pref_rec.procedure_name);
	end loop;
    end clean_schema;

end sws_procedure;
/
-- create a public synonym, so that 
-- all methods could access them
create public synonym sws_procedure for
ctxsys.sws_procedure;

grant execute on sws_procedure to ctxapp;













