-- 
-- packages/site-wide-search/sql/sws-reindex.sql
-- @author khy@ardigita.com
-- @creation-date 2001-02-09
-- @cvs-id $Id$
-- 

-- Rebuilds the index. If this is an upgrade, please becarefull
-- not to run this when the batch job is running to reindex your data.
begin
   sws_service.rebuild_index;
end;
/
show errors;