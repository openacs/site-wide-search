--
-- packages/site-wide-search/sql/index.sql
-- 
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
--

-- create the procedure within intermedia schema
declare 
    v_schema		varchar2(30);
    v_proc_name		varchar2(30);
    v_exist_p		char(1);
    v_cursor		integer;
    v_execute_result	integer;
    v_code		varchar2(4000);
begin
    
    select username into v_schema
    from user_users;

    v_exist_p := 'f';

    -- check if the procedure was already created
    v_proc_name := sws_procedure.get_actual_procedure (
		     schema	    => v_schema,
		     procedure_name => 'sws_index_proc'
		   );
    
    select decode (count(*), 0, 'f', 't') into v_exist_p
    from dual where v_proc_name is not null;

    -- create new procedure within ctxsys schema 
    -- The created procedure calls the sws_service.sws_index_proc
    if v_exist_p = 'f' then
	v_proc_name := sws_procedure.create_procedure (
			    schema	    => v_schema,
			    procedure_name  => 'sws_index_proc',
			    call_procedure  => 'sws_service.sws_index_proc'
			); 
    end if;


    -- Check if the ctxsys user_datastore procedure preference was already declared.
    select decode (count(*), 0, 'f', 't') into v_exist_p 
    from ctxsys.ctx_preferences
    where pre_name = 'SWS_USER_DATASTORE'
    and pre_owner = v_schema;

    -- create new user_datastore procedure preference 
    if v_exist_p = 'f' then
        ctx_ddl.create_preference('sws_user_datastore','user_datastore');
	ctx_ddl.set_attribute('sws_user_datastore','procedure',v_proc_name);
	ctx_ddl.set_attribute('sws_user_datastore','output_type','blob');
    end if;

    -- If the index does not exist , create one.
    select decode(count(*),0,'f','t') into v_exist_p
    from dual
    where exists (
	select 1 
	from user_indexes
	where index_name = 'SWS_SRCH_CTS_DS_IIDX');

    if v_exist_p = 'f' then 
        v_code := '
	    create index sws_srch_cts_ds_iidx on sws_search_contents (data_store)
		indextype is ctxsys.context 
		parameters (''datastore sws_user_datastore
		     filter ctxsys.INSO_FILTER''
		)';

	dbms_output.put_line ('code => '||v_code);

	v_cursor := dbms_sql.open_cursor;
	dbms_sql.parse(v_cursor, v_code, dbms_sql.native);
	v_execute_result := dbms_sql.execute(v_cursor);
	dbms_sql.close_cursor(v_cursor);
    end if;
end;
/

create table sws_job (
    jobno	    number
);


-- Batch job to run site wide search reindexing every two hours
VARIABLE jobno number;

begin
    dbms_job.submit(:jobno	    ,
	'sws_service.rebuild_index;' ,
	sysdate			    ,
	'sysdate + .17'
    );   

    insert into sws_job (
	jobno 
    ) values (
	:jobno
    );
    commit;
end;
/







