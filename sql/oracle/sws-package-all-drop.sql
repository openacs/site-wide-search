--
-- packages/site-wide-search/sql/sws-package-all-drop.sql
-- 
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
--

drop trigger content_revision_itrg;
drop trigger content_revision_utrg;
drop trigger content_revision_dtrg;
drop function im_convert;
drop procedure im_convert_length_check;
@index-remove 
@sws-service-interface-remove
@pot-remove
@search-tables-remove
@acs-object-util-remove




