-- 
-- packages/site-wide-search/sql/sws-package-all.sql
-- 
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
-- 

@acs-object-util
@search-tables
@pot
@sws-service-interface
@index

-- Add content cr_revisions table 
-- Triggers populate acs_contents and sws_search_contents
-- Note: we do not copy content over from cr_revisions
begin
    insert into acs_contents (
	content_id,
	content
    ) select revision_id    ,
	     empty_blob()
    from cr_revisions cr 
    where not exists (
	      select 1 
	      from acs_contents acs 
	      where acs.content_id = cr.revision_id);
end;
/

begin
    insert into sws_search_contents (
	 content_id,
	 data_store
    )
    select content_id ,
         'a'
    from acs_contents ac 
    where searchable_p = 't' 
    and not exists (
	select 1 
	from sws_search_contents ssc
	where ssc.content_id = ac.content_id);
end;
/

-- Triggers for acs_contents to insert, update, or delete cr_revision entries in the sws_search_contents table
-- for inclusion/exclusion from site wide search. Currently, most of the ACS contents are
-- stored in acs_revision. 
create or replace trigger content_revision_itrg
after insert on cr_revisions
for each row
declare
    v_bdata	blob;
    v_size	integer;
begin
   
    insert into acs_contents (
	content_id,
	searchable_p)
     values ( 
	:new.revision_id,
	't'
    );
end;
/

create or replace trigger content_revision_utrg
after update on cr_revisions
for each row
declare
    v_bdata	blob;
    v_size	integer;
begin
    update acs_contents 
    set nls_language    = :new.nls_language,
	mime_type	= :new.mime_type
    where content_id	= :new.revision_id;
end;
/

create trigger content_revision_dtrg
after delete on cr_revisions
for each row
declare
begin
    delete from acs_contents
    where content_id = :old.revision_id;
end;
/


-- if we pass in a very long string to im_convert, we will end up with internal 
--  strings that are too long. Because this is relatively hard to debug,
--  we wrote im_convert_length_check to throw a more appropriate error message
-- Note that we raise an exception because passing such a long query to
--  interMedia is pretty slow. Alternative to the application error are to 
--    1. return the string as is
--    2. increase the max length from 256 to 1024
-- mbryzek@arsdigita.com, 7/6/2000
create or replace procedure im_convert_length_check ( 
    p_string IN varchar2,
    p_number_chars_to_append IN number,
    p_max_length IN number, 
    p_variable_name IN varchar2 
)
is
begin
    if nvl(length(p_string),0) + p_number_chars_to_append > p_max_length then
	raise_application_error(-20000, 'Variable "' || p_variable_name || '" exceeds ' || p_max_length || ' character declaration');
    end if;
end;
/
show errors;


-- Query to take free text user entered query and from it into something
-- that will make interMedia happy. Provided by Oracle.
create or replace function im_convert(
    query in varchar2 default null
) return varchar2
is
    i   number :=0;
    len number :=0;
    char varchar2(1);
    minusString varchar2(256) := '';
    plusString varchar2(256) := ''; 
    mainString varchar2(256) := ''; 
    mainAboutString varchar2(500) := ''; 
    finalString varchar2(500) := ''; 
    hasMain number :=0;
    hasPlus number :=0;
    hasMinus number :=0;
    token varchar2(256);
    tokenStart number :=1;
    tokenFinish number :=0;
    inPhrase number :=0;
    inPlus number :=0;
    inWord number :=0;
    inMinus number :=0;
    completePhrase number :=0;
    completeWord number :=0;
    code number :=0;  
begin
  
    len := length(query);

    -- we iterate over the string to find special web operators
    for i in 1..len loop
	char := substr(query,i,1);
	if(char = '"') then
	    if(inPhrase = 0) then
		inPhrase := 1;
		tokenStart := i;
	    else
		inPhrase := 0;
		completePhrase := 1;
		tokenFinish := i-1;
	    end if;
	elsif(char = ' ') then
	    if(inPhrase = 0) then
		completeWord := 1;
		tokenFinish := i-1;
	    end if;
	elsif(char = '+') then
	    inPlus := 1;
	    tokenStart := i+1;
	elsif((char = '-') and (i = tokenStart)) then
	    inMinus :=1;
	    tokenStart := i+1;
	end if;

	if(completeWord=1) then
	    token := '{ '||substr(query,tokenStart,tokenFinish-tokenStart+1)||' }';      
	    if(inPlus=1) then
		im_convert_length_check(plusString, 4+length(token), 256, 'plusString');
		plusString := plusString||','||token||'*10';
		hasPlus :=1;	
	    elsif(inMinus=1) then
		im_convert_length_check(minusString, 4+length(token), 256, 'minusString');
		minusString := minusString||'OR '||token||' ';
		hasMinus :=1;
	    else
		im_convert_length_check(mainString, 6+length(token), 256, 'mainString');
		mainString := mainString||' NEAR '||token;
		im_convert_length_check(mainAboutString, 1+length(token), 500, 'mainAboutString');
		mainAboutString := mainAboutString||' '||token; 
		hasMain :=1;
	    end if;
	    tokenStart  :=i+1;
	    tokenFinish :=0;
	    inPlus := 0;
	    inMinus :=0;
	end if;
	completePhrase := 0;
	completeWord :=0;
    end loop;

    -- find the last token
    token := '{ '||substr(query,tokenStart,len-tokenStart+1)||' }';
    if(inPlus=1) then
	im_convert_length_check(plusString, 4+length(token), 256, 'plusString');
	plusString := plusString||','||token||'*10';
	hasPlus :=1;	
    elsif(inMinus=1) then
	im_convert_length_check(minusString, 4+length(token), 256, 'minusString');
	minusString := minusString||'OR '||token||' ';
	hasMinus :=1;
    else
	im_convert_length_check(mainString, 6+length(token), 256, 'mainString');
	mainString := mainString||' NEAR '||token;
	im_convert_length_check(mainAboutString, 1+length(token), 500, 'mainAboutString');
	mainAboutString := mainAboutString||' '||token; 
	hasMain :=1;
    end if;

  
    mainString := substr(mainString,6,length(mainString)-5);
    mainAboutString := replace(mainAboutString,'{',' ');
    mainAboutString := replace(mainAboutString,'}',' ');
    mainAboutString := replace(mainAboutString,')',' ');	
    mainAboutString := replace(mainAboutString,'(',' ');
    plusString := substr(plusString,2,length(plusString)-1);
    minusString := substr(minusString,4,length(minusString)-4);

    -- let's just check once for the length of finalString... note this uses the 
    -- longest possible string that is created in the rest of this function
    im_convert_length_check(finalString, nvl(length(mainString),0) + nvl(length(mainAboutString),0) + nvl(length(minusString),0) + nvl(length(plusString),0) + 30, 500, 'finalString');

    -- we find the components present and then process them based on the specific combinations
    code := hasMain*4+hasPlus*2+hasMinus;
    if(code = 7) then
	finalString := '('||plusString||','||mainString||'*2.0,about('||mainAboutString||')*0.5) NOT ('||minusString||')';
    elsif (code = 6) then  
	finalString := plusString||','||mainString||'*2.0'||',about('||mainAboutString||')*0.5';
    elsif (code = 5) then  
	finalString := '('||mainString||',about('||mainAboutString||')) NOT ('||minusString||')';
    elsif (code = 4) then  
	finalString := mainString; 
	finalString := replace(finalString,'*1,',NULL); 
	finalString := '('||finalString||')*2.0,about('||mainAboutString||')';
    elsif (code = 3) then  
	finalString := '('||plusString||') NOT ('||minusString||')';
    elsif (code = 2) then  
	finalString := plusString;
    elsif (code = 1) then  
	-- not is a binary operator for intermedia text
	finalString := 'totallyImpossibleString'||' NOT ('||minusString||')';
    elsif (code = 0) then  
	finalString := '';
    end if;

    return finalString;
end;
/
show errors;














