

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
\ir '../100-harfbuzz.sql'
-- \set filename interplot/db/tests/080-intertext.sql
\set filename interplot/db/tests/100-harfbuzz.tests.sql
\set signal :red

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists HARFBUZZ_X cascade; create schema HARFBUZZ_X;




-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create table HARFBUZZ_X.slabjoints_01_probes as ( select
    *
  from INTERTEXT_SLABS.shyphenate( 'supercoherent amazingly eloquent fi'::text ) as r1
  -- , lateral ( select 42 ) as d2 ( x )
  );

-- insert into HARFBUZZ_X.slabjoints_01_probes ( vnr, slab, joint ) values
--   ( '{1,1}', 'amazingly', '°' ),
--   ( '{3,1}', 'eloquent', '°' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create view HARFBUZZ_X.slabwidths_jsonb as ( select
    r1.vnr        as vnr,
    r1.slab       as slab,
    r1.joint      as joint,
    r3.width      as width
  from HARFBUZZ_X.slabjoints_01_probes                      as r1,
  -- lateral ( select '/home/flow/jzr/hengist/assets/jizura-fonts/FandolKai-Regular.otf' as font_path ) as r12,
  lateral ( select '/home/flow/jzr/hengist/assets/jizura-fonts/lmroman10-italic.otf' as font_path ) as r12,
  lateral HARFBUZZ.metrics_from_text_as_jsonb( r12.font_path, r1.slab )  as r3 ( width )
  -- lateral to_char( d2.width, '99,990.000' )                 as r3 ( width )
  order by vnr );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
create view HARFBUZZ_X.slabwidths_rows as ( select
    -- r1.vnr        as vnr,
    -- r1.slab       as slab,
    -- r1.joint      as joint,
    -- r3.width      as width
    r4.vnr        as vnr,
    r1.slab       as slab,
    r1.joint      as joint,
    r3.gid        as gid,
    r3.dx         as dx
  from HARFBUZZ_X.slabjoints_01_probes                      as r1,
  -- lateral ( select '/home/flow/jzr/hengist/assets/jizura-fonts/FandolKai-Regular.otf' as font_path ) as r12,
  lateral ( select '/home/flow/jzr/hengist/assets/jizura-fonts/lmroman10-italic.otf' as font_path ) as r12,
  lateral HARFBUZZ.metrics_from_text_as_rows( r12.font_path, r1.slab )  as r3,
  -- lateral ( select array[ r1.vnr[ 1 ], r3.nr ] ) as r4 ( vnr )
  lateral VNR.cat( r1.vnr, r3.vnr ) as r4 ( vnr )
  -- lateral to_char( d2.width, '99,990.000' )                 as r3 ( width )
  order by
    -- gid,
    -- dx,
    vnr
    );




/* ###################################################################################################### */
\echo :signal ———{ :filename 5 }———:reset
-- select * from HARFBUZZ_X.slabjoints_01_probes order by vnr;
-- select * from HARFBUZZ_X.slabwidths_jsonb;
select * from HARFBUZZ_X.slabwidths_rows;
-- select * from HARFBUZZ.get_detailed_metrics( u&'abc' );
-- -- select * from HARFBUZZ.get_detailed_metrics( u&'布列塔尼语' );
-- select * from HARFBUZZ.get_detailed_metrics( u&'布列塔尼语（Brezhoneg，法文叫Breton）。' );





/* ###################################################################################################### */
\echo :red ———{ :filename 7 }———:reset
\quit




-- do $$ begin perform INVARIANTS.validate(); end; $$;

-- -- instead.








