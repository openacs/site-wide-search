--
-- packages/site-wide-search/sql/intermedia-setup-remove.sql
-- 
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
--
drop sequence sws_procedures_sequence;
drop public synonym sws_procedure;
drop package sws_procedure;
drop table sws_procedures;