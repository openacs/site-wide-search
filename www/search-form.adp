<formtemplate id="search_form">
<table>
<tr valign="top"><th align=right>
Key Words:</th>
<td><formwidget id="query_string"></td></tr>

<if @subsite_node_option_p@ eq 1>
    <tr>
    <th align=right  valign=top>
    In:</th>
    <td>
    <formwidget id="subsites"></td></tr>
</if>

<if @group_by_p@ eq 1>
    <tr valign=top><th align=right>Group by:</th>
    <td>
    <formgroup id="grouping">
    <br>@formgroup.widget@ @formgroup.label@
    </formgroup>
    </td></tr>
</if>

<if @search_methods_p@ eq 1>
    <tr valign=top><th align=right>
    Searching<br>Method:</th><td>
    <formgroup id="search_methods">
    <br>@formgroup.widget@ @formgroup.label@
    </formgroup>
    </td></tr>
</if>
<tr><td></td>
<td><input type=submit value="Go"></td></tr>
</table>
</formtemplate>







