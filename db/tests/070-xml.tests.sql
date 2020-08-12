

-- \set ECHO queries

/* ###################################################################################################### */
\ir '../_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
-- ---------------------------------------------------------------------------------------------------------
begin transaction;

\ir '../070-xml.sql'
-- \set filename interplot/db/tests/080-intertext.sql
\set filename interplot/db/tests/070-xml.tests.sql
\set signal :red
do $$ begin perform log( 'XML tests' ); end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists XML_X cascade; create schema XML_X;




-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
create table XML_X.probes_and_matchers_1 (
  title     text,
  probe     text,
  matcher   text,
  result    text );

create table XML_X.probes_and_matchers_2 (
  title     text,
  probe_1   text,
  probe_2   text,
  matcher   text,
  result    text );

-- select ( '{}'::jsonb )->'x';
-- select pg_typeof( ( '{}'::jsonb )->'x' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
insert into XML_X.probes_and_matchers_1 ( title, probe, matcher ) values
  ( 'escape_text',               'helo',         'helo'                      ),
  ( 'escape_text',               'helo>>>world', 'helo&gt;&gt;&gt;world'     ),
  ( 'escape_text',               '<13&14>',      '&lt;13&amp;14&gt;'         ),
  ( 'escape_text',               '<helo',        '&lt;helo'                  ),
  ( 'as_attributes',             '{"foo":"bar"}', 'foo=''bar'''                  ),
  ( 'as_attributes',             '{"foo":"bar","height":33}', 'foo=''bar'' height=''33'''                  ),
  ( 'tag', '{"$key":"<tag","name":"div","atrs":{"width":25,"height":120}}',              '<div width=''25'' height=''120''>'        ),
  ( 'tag', '{"$key":">tag","name":"div","atrs":{"width":25,"height":120}}',              '</div>'                                   ),
  ( 'tag', '{"$key":"^tag","name":"div","atrs":{"width":25,"height":120}}',              '<div width=''25'' height=''120''></div>'  ),
  ( 'tag', '{"$key":"^tag","name":"div","short":true,"atrs":{"width":25,"height":120}}', '<div width=''25'' height=''120''/>'       ),
  ( 'tag', '{"$key":"<tag","name":"div"}',                                               '<div>'                                    ),
  ( 'tag', '{"$key":">tag","name":"div"}',                                               '</div>'                                   ),
  ( 'tag', '{"$key":"^tag","name":"div"}',                                               '<div></div>'                              ),
  ( 'tag', '{"$key":"^tag","name":"div","short":true}',                                  '<div/>'                                   ),
  ( 'escape_attribute_value', '<"helo">',        '''&lt;"helo"&gt;'''                  ),
  ( 'escape_attribute_value', '<''helo''>',      '''&lt;&#39;helo&#39;&gt;'''                  );
update XML_X.probes_and_matchers_1 set result = XML.escape_text( probe ) where title = 'escape_text';
update XML_X.probes_and_matchers_1 set result = XML.escape_attribute_value( probe ) where title = 'escape_attribute_value';
update XML_X.probes_and_matchers_1 set result = XML.as_attributes( probe::jsonb ) where title = 'as_attributes';
update XML_X.probes_and_matchers_1 set result = XML.tag( probe::jsonb ) where title = 'tag';

insert into XML_X.probes_and_matchers_2 ( title, probe_1, probe_2, matcher ) values
  ( 'as_attribute', 'width', '25',    'width=''25'''                  );
update XML_X.probes_and_matchers_2 set result = XML.as_attribute( probe_1, probe_2 ) where title = 'as_attribute';

-- ---------------------------------------------------------------------------------------------------------
insert into INVARIANTS.tests select
    'XML'                                           as module,
    r1.title                                        as title,
    row( result, matcher )::text                    as values,
    ( r1.result = r1.matcher )                      as is_ok
  from XML_X.probes_and_matchers_1 as r1;

-- ---------------------------------------------------------------------------------------------------------
insert into INVARIANTS.tests select
    'XML'                                           as module,
    r1.title                                        as title,
    row( result, matcher )::text                    as values,
    ( r1.result = r1.matcher )                      as is_ok
  from XML_X.probes_and_matchers_1 as r1;

select * from XML_X.probes_and_matchers_1;
select * from INVARIANTS.tests;
select * from INVARIANTS.violations;
-- select count(*) from ( select * from INVARIANTS.violations limit 1 ) as x;
-- select count(*) from INVARIANTS.violations;
do $$ begin perform INVARIANTS.validate(); end; $$;

( select XML.tag( '{"$key":"<tag","name":"div","atrs":{"width":25,"height":120}}'::jsonb ) ) union all
( select XML.tag( '{"$key":">tag","name":"div","atrs":{"width":25,"height":120}}'::jsonb ) ) union all
( select XML.tag( '{"$key":"^tag","name":"div","atrs":{"width":25,"height":120}}'::jsonb ) ) union all
( select XML.tag( '{"$key":"^tag","name":"div","short":true,"atrs":{"width":25,"height":120}}'::jsonb ) ) union all
( select null where false );


/* ###################################################################################################### */
\echo :red ———{ :filename 7 }———:reset
\quit




-- do $$ begin perform INVARIANTS.validate(); end; $$;

-- -- instead.








