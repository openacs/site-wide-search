-- 
-- packages/site-wide-search/sql/search-tables-remove.sql
--
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
--

drop table sws_search_contents;

begin
    acs_interface.delete (
	interface_name		=> 'sws_display',
	programming_language	=> 'pl/sql'
    );
    
    acs_interface.delete (
	interface_name		=> 'sws_indexing',
	programming_language	=> 'pl/sql'
    );
end;
/










