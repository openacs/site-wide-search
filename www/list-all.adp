<master src="master">
<property name="context_bar">{All Content}</property>
<property name="title">All Content</property>

<if @content_list:rowcount@ gt 0>
       <multiple name=content_list>
       <b>@content_list.app_name@</b>       
       <table>
       <group column=app_name>
       <tr><td><a href="@content_list.url@">@content_list.title@</a></td>
           <td align=left>[<a href="intermedia-categories?content_id=@content_list.content_id@">categories</a>]</td
       </tr>
       </group>
       </table>
       </multiple>
</if>

<if @content_list:rowcount@ eq 0>
     Empty content
</if>
    
       