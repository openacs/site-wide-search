ad_page_contract {
    Search Widget
    
    @author Khy Huang (khy@arsdigita.com)
    @creation-date 2000-12-09
    @cvs-id $Id$
} {
    {subsite_node_option_p:naturalnum 1}
    {group_by_p:naturalnum 1}
    {search_methods_p:naturalnum 1}
} -properties {
    subsite_node_option_p:onevalue
    group_by_p:onevalue
    search_methods_p:onevalue
}

template::form create search_form


set subsites [db_list_of_lists subsites "
    select lpad(' ',18*(level-1),'&nbsp;')||name||'/',
	   (select apm.package_id from apm_packages apm where apm.package_id = sn.object_id)
    from site_nodes sn
    start with sn.node_id = site_node.node_id('/')
    connect by parent_id = prior node_id  	 
"]

template::element create search_form subsites \
    -widget multiselect \
    -options $subsites \
    -label "Sub Site"

template::element create search_form query_string \
    -widget text \
    -label  "Key Words"

template::element create search_form grouping \
    -widget checkbox \
    -options  { {{By Application} by_app} }

template::element create search_form search_methods \
    -widget radio \
    -options { {{Intelligent Search} {default}} {{Match All Words (AND)} all} \
		{{Match Any Words (OR)} any} } \
    -value any

if {[template::form is_submission search_form]} {
    ad_returnredirect "search?[export_entire_form_as_url_vars]"
    ad_script_abort
}

ad_return_template









