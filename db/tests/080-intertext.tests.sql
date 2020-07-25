

-- \set ECHO queries

/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
-- ---------------------------------------------------------------------------------------------------------
begin transaction;

\ir '../080-intertext.sql'
\set filename interplot/db/tests/080-intertext.tests.sql
\set signal :red

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists INTERTEXT_X cascade; create schema INTERTEXT_X;


-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 1 }———:reset

-- select '"he\"lo"'::jsonb#>>'{}';
-- select INTERTEXT.as_text( '"he\"lo"'::jsonb );
-- select INTERTEXT.as_text( 'true'::jsonb );
-- select INTERTEXT.as_text( '42'::jsonb );

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 1 }———:reset
-- select * from INTERTEXT_HYPH.reveal_hyphenate( 'amazingly eloquent lubrication'::text );

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 1 }———:reset
-- select * from HARFBUZZ.positions_from_text( e'这个东西' );
-- select * from HARFBUZZ.positions_from_text( e'affix' );
-- -- select * from HARFBUZZ.positions_from_text( e'xحرف‌بازx' );
-- select * from HARFBUZZ.positions_from_text( e'حرف‌بازx' );
-- -- select * from jsonb_populate_recordset( null::HARFBUZZ.x, HARFBUZZ.positions_from_text( 42 ) );
-- select INTERTEXT_HYPH.hyphenate( 'some text to be hyphenated' );
-- -- select INTERTEXT_SLABS.slabjoints_from_text( 'some text to be hyphenated' );
-- select * from INTERTEXT_SLABS.shyphenate2( 'some text to be hyphenated'::text );
-- -- select * from INTERTEXT_SLABS.shyphenate2( 'formatstr is a format string that specifies how the result should be formatted. Text in the format string is copied directly to the result, except where format specifiers are used. Format specifiers act as placeholders in the string, defining how subsequent function arguments should be formatted and inserted into the result. Each formatarg argument is converted to text according to the usual output rules for its data type, and then formatted and inserted into the result string according to the format specifier(s).'::text ) as slabjoint order by slabjoint;
-- select * from INTERTEXT_HYPH.reveal_hyphenate( 'amazingly eloquent lubrication indeed'::text );

-- create table INTERTEXT_X.slabjoints (
--     vnr   VNR.vnr unique not null primary key,
--     slab  text,
--     joint text );

/*

# Terminology

* **slab**—short for '(typographic) syllable'
* **joint**
* **slabjoint**
* **segment**
* **(typographic) word**

*/


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
create materialized view INTERTEXT_X.slabjoints_01_probes as
  select * from INTERTEXT_SLABS.shyphenate(
    'amazingly eloquent'::text ) as slabjoint;
    -- 'formatstr is a format string that specifies how the result should be formatted.'::text ) as slabjoint;

-- ---------------------------------------------------------------------------------------------------------
create view INTERTEXT_X.slabjoints_01_matchers as
  ( select null::VNR.vnr as vnr, null::text as slab, null::text as joint where false ) union all
  ( select '{0}', 'amaz',  '=' ) union all
  ( select '{1}', 'ingly', '°' ) union all
  ( select '{2}', 'elo',   '=' ) union all
  ( select '{3}', 'quent', '#' ) union all
  ( select null, null, null where false );

-- ---------------------------------------------------------------------------------------------------------
insert into INVARIANTS.tests select
    'INTERTEXT_X'                                             as module,
    'slabjoints_01_slabs_and_joints'                as title,
    row( results, matchers )::text   as values,
    ( results.slab = matchers.slab ) and ( results.joint = matchers.joint )   as is_ok
  from INTERTEXT_X.slabjoints_01_probes               as results
  full outer join INTERTEXT_X.slabjoints_01_matchers  as matchers using ( vnr );

-- ---------------------------------------------------------------------------------------------------------
insert into INVARIANTS.tests select
    'INTERTEXT_X'                                   as module,
    'slabjoints_01_rowcount'              as title,
    row( p_rowcount, m_rowcount )::text   as values,
    p_rowcount = m_rowcount               as is_ok
  from
    lateral ( select count(*) as p_rowcount from INTERTEXT_X.slabjoints_01_probes   ) as d1 ( p_rowcount ),
    lateral ( select count(*) as m_rowcount from INTERTEXT_X.slabjoints_01_matchers ) as d2 ( m_rowcount );

select * from INVARIANTS.tests;
select * from INVARIANTS.violations;
-- select count(*) from ( select * from INVARIANTS.violations limit 1 ) as x;
-- select count(*) from INVARIANTS.violations;
do $$ begin perform INVARIANTS.validate(); end; $$;



-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
create function INTERTEXT.XXX_expand_slabjoints( ¶slab text, ¶joint text )
  returns setof text strict immutable language plpgsql as $$
  declare
  begin
    case ¶joint
      when '=' then
        return next ¶slab;
        return next ¶slab || '-';
      when '°' then
        return next ¶slab;
      when '#' then
        return next ¶slab;
      else
        return next null;
        end case;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
select
    d1.slab,
    d1.joint,
    d2.x
  from INTERTEXT_X.slabjoints_01_probes as d1,
  lateral INTERTEXT.XXX_expand_slabjoints( slab, joint ) as d2 ( x )
  ;



/* ###################################################################################################### */
\echo :red ———{ :filename 7 }———:reset
\quit






