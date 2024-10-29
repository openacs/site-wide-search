# /packages/bboard/www/search-redirect.tcl

ad_page_contract {
    Page that redirects for site-wide search

    @author Khy Huang (khy@arsdigita.com)
    @creation-date 2000-01-19
    @cvs-id $Id$
} {
    message_id:naturalnum,notnull
}

set forum_id -1

set forum_id [db_string first_forum_for_message {
    select forum_id 
    from bboard_forum_message_map
    where message_id = :message_id
    and   RowNum = 1} ]


ad_returnredirect "message?[export_url_vars forum_id message_id]"
