ad_library {
    Functions for cleaning search strings

    @creation-date 2000-12-11
    @author Khy Huang <khy@arsdigita.com>
    @cvs-id $Id$
}

ad_proc -public sws_remove_or {
    {query_string}
} {
    Remove the 'or' operators from query string
} {
    set new_string [list]

    foreach el $query_string {
	if {![string compare [string tolower $el] "|"] == 0 &&
	    ![string compare [string tolower $el] "or"] == 0 } {
	    lappend new_string $el     
	}
    }
    return $new_string
}

ad_proc -public sws_remove_and {
    {query_string}
} {
    Remove the 'and' operators from query string
} {
    set new_string [list]

    foreach el $query_string {
	if {![string compare [string tolower $el] "and"] == 0 &&
	    ![string compare [string tolower $el] "&"] == 0 } {
	    lappend new_string $el     
	}
    }
    return $new_string
}



ad_proc -private sws_package_url {} {
    set sql "select site_node.url(s.node_id) as package_url
    from site_nodes s, apm_packages a
    where s.object_id = a.package_id
    and lower(a.package_key) = 'site-wide-search' 
    and RowNum = 1"

    if { [db_0or1row get_package_url $sql] } {
	return $package_url
    } else {
	# log an error message
	ns_log "Notice" "The Site Wide Search package is not mounted."
	return ""
    }
}
