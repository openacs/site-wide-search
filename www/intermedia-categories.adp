<master src="master">
<property name="title">The categories for '@title@'</property>
<property name="context">categories</property>

<if @intermedia_categories_list:rowcount@ gt 0>
<ul>    <multiple name=intermedia_categories_list>   
	<li> @intermedia_categories_list.theme@ (@intermedia_categories_list.weight@)
    </multiple>
</ul>
</if>

<if @intermedia_categories_list:rowcount@ eq 0>
    Intermedia did not find any categories for '@title@'.
</if>