ad_page_contract {
    Displays all intermedia themes for one content.

    @author Khy Huang
    @creation-date 2001-02-12
    @cvs-id $Id$
} {
    content_id:integer 
} -properties {
    intermedia_categories_list:multirow
    title
}

db_dml delete_from_themes {
    delete from ctx_themes 
    where query_id = :content_id
}

db_exec_plsql ctx_themes_delete "
    begin
        ctx_doc.themes('sws_srch_cts_ds_iidx','$content_id','ctx_themes',:content_id);   
    end;
"

set title [db_string content_item_query {
    select sws_service.get_content_title(content_id) as title
    from sws_search_contents 
    where content_id = :content_id
}]

db_multirow intermedia_categories_list intermedia_theme_query {
    select theme, 
	   weight
    from   ctx_themes ctt
    where  query_id = :content_id
}

ad_return_template








