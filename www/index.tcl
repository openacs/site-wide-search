ad_page_contract {
    Displays a form for entering a search term 

    @author Khy Huang (khy@arsdigita.com)
    @creation-date 2000-12-09
    @cvs-id $Id$	
} {
    {subsite_node_option_p:naturalnum 1}
    {group_by_p:naturalnum 1}
    {search_methods_p:naturalnum 1}
} -properties {
    context:onevalue
}

set context {}

set title "Search Page"



