--
-- packages/site-wide-search/sql/index-remove.sql
-- 
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
--

-- PL/SQL block cleans up the Intermedia setup for this schema
declare
    v_schema		varchar2(30);
    v_cursor		integer;
    v_code		varchar2(4000);
    v_execute_result	integer;
    v_exist_p		char(1);
begin
    select username into v_schema
    from user_users;

    sws_procedure.clean_schema(v_schema);

    -- if index exist, remove index
    select decode(count(*),0,'f','t') into v_exist_p
    from dual
    where exists (
	select 1 
	from user_indexes
	where index_name = 'SWS_SRCH_CTS_DS_IIDX');

    if v_exist_p = 't' then 

        v_code := 'drop index sws_srch_cts_ds_iidx';

	dbms_output.put_line ('code => '||v_code);

	v_cursor := dbms_sql.open_cursor;
	dbms_sql.parse(v_cursor, v_code, dbms_sql.native);
	v_execute_result := dbms_sql.execute(v_cursor);
	dbms_sql.close_cursor(v_cursor);
    end if;

    -- remove user_datastore preference
    ctx_ddl.drop_preference('sws_user_datastore'); 
end;
/

begin
    for sws_job_row in (select jobno from sws_job) loop
	dbms_job.remove(sws_job_row.jobno);
    end loop;
end;
/

drop table sws_job;




