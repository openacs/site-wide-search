ad_page_contract {
    Search Engine

    @author Khy Huang (khy@arsdigita.com)
    @creation-date 2000-12-11
    @cvs-id $Id$
} {
    query_string:notnull,trim
    {subsites:multiple	""}
    {grouping	""}
    {search_methods ""}
} -properties {
    search_result:multirow
    group_by:onevalue
    final_query_str:onevalue
}

set user_id [ad_conn user_id]

# clean up strings depending on search methods
# AND condition 
if {[string compare all [string tolower $search_methods]] == 0} {
    set query_string [sws_remove_or $query_string]
    set query_string [sws_remove_and $query_string]

    set and_condition {}
    set row_count 0
    foreach el $query_string {
	incr row_count 1
	if {$row_count > 1} {
	    lappend and_condition and $el
	} else {
	    lappend and_condition $el
	}
    }
    set query_string [join $query_string " "]   
    set final_query_str [db_string im_query_string "select im_convert(:query_string) from dual"]

    if {![empty_string_p $and_condition]} {
	set final_query_str "$and_condition, $final_query_str"        
    }

} elseif {[string compare any [string tolower $search_methods]] == 0} {
# OR condition 

    set query_string [sws_remove_or $query_string]
    set query_string [sws_remove_and $query_string]

    set or_condition {} 
    set row_count 0   
    foreach el $query_string {
	incr row_count 1
	if {$row_count > 1} {
	    lappend or_condition or $el
	} else {
	    lappend or_condition $el
	}
    }
    
    set query_string [join $query_string " "]
    set final_query_str [db_string im_query_string "select im_convert(:query_string) from dual"]

    if {![empty_string_p $or_condition]} {
	set final_query_str "$or_condition, $final_query_str"        
    }

} else {
    set final_query_str [db_string im_query_string "select im_convert(:query_string) from dual"]
}

# build string to restrict the search within a subsite if subsite is specified. 
if {[llength $subsites] > 0} {
    set in_subsites "and exists (select 1 
		from acs_object_contexts aoc
                where (aoc.object_id = ssc.application_id 
			and   aoc.ancestor_id in ([join $subsites ", "]))
		or    (ssc.application_id in ([join $subsites ", "])) )"
} else {
    set in_subsites ""
}


if {[string compare by_app $grouping]  != 0} {

    set query "select score(1) as rank, 
		      sws_service.get_content_title(ssc.content_id) as title,
		      sws_service.get_content_url(ssc.content_id) as url,
		      apm_package.name(ssc.application_id) as application_name
	       from acs_contents acc,
		    sws_search_contents ssc 
	       where acc.content_id = ssc.content_id 
	       and   acc.searchable_p = 't' 
	       and   contains(ssc.data_store,:final_query_str,1) > 0 $in_subsites
	       and   decode(permission_req,null,'t',
			 acs_permission.permission_p(acc.content_id, :user_id, ssc.permission_req)) = 't'
	       order by score(1) desc"

    set group_by 0
} else {

    set query "select score(1) as rank, 
		      sws_service.get_content_title(acc.content_id) as title,
		      sws_service.get_content_url(acc.content_id) as url,
		      apm_package.name(ssc.application_id) as application_name
	       from acs_contents acc,
		    sws_search_contents ssc 
	       where acc.content_id = ssc.content_id 
	       and   acc.searchable_p = 't' 
	       and   contains(ssc.data_store,:final_query_str,1) > 0 $in_subsites
	       and   decode(permission_req,null,'t',
			 acs_permission.permission_p(acc.content_id, :user_id, ssc.permission_req)) = 't'
	       order by apm_package.name(ssc.application_id), score(1) desc"

    set group_by 1
}


db_multirow search_result result_query $query 

ad_return_template



 










