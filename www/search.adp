<master src="master">
<property name="title">Search Results</property>
<property name="context">result</property>

<if @search_result:rowcount@ gt 0>
    <if @group_by@ eq 1>
	<multiple name=search_result>   
	<b>@search_result.application_name@ </b><ul>
	<group column=application_name>
	<li><a href="@search_result.url@">@search_result.title@ (@search_result.rank@)</a>
	</group>
	</ul>
	</multiple>
    </if>
    <if @group_by@ eq 0>
	<ul>
	<multiple name=search_result>   
	<li><a href="@search_result.url@">@search_result.title@ (@search_result.application_name@ @search_result.rank@)</a>
	</multiple>
	</ul>
    </if>
</if>

<if @search_result:rowcount@ eq 0>
    There are no items found for '@query_string@'.
</if>







