ad_page_contract {
    Displays the all the content in system

    @author Khy Huang (khy@arsdigita.com)
    @creation-date    2000-12-09
    @cvs-id $Id$
} {
} -properties {
    content_list:multirow
}

set query "select sws_service.get_content_title(ssc.content_id) as title,
                  sws_service.get_content_url(ssc.content_id) as url,
                  apm_package.name(ssc.application_id) app_name,
                  ssc.content_id
           from   sws_search_contents ssc ,
                  acs_contents acc
	   where  
		  acc.content_id = ssc.content_id"

db_multirow content_list list_all_query $query

ad_return_template

