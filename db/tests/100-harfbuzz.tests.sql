

-- \set ECHO queries

/* ###################################################################################################### */
\ir '../_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager off
\timing off
-- ---------------------------------------------------------------------------------------------------------
begin transaction;

\ir '../080-intertext.sql'
\ir '../100-harfbuzz.sql'
\ir '../900-dev.sql'
-- \set filename interplot/db/tests/080-intertext.sql
\set filename interplot/db/tests/100-harfbuzz.tests.sql
\set signal :red

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists HARFBUZZ_T cascade; create schema HARFBUZZ_T;




-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------


/* ###################################################################################################### */
\echo :signal ———{ :filename 15 }———:reset
-- select * from HARFBUZZ_X.slabwidths_jsonb;
-- select * from HARFBUZZ.get_detailed_metrics( u&'abc' );
-- -- select * from HARFBUZZ.get_detailed_metrics( u&'布列塔尼语' );
-- select * from HARFBUZZ.get_detailed_metrics( u&'布列塔尼语（Brezhoneg，法文叫Breton）。' );

-- select * from HARFBUZZ_X.slabwidths_02;
-- select INTERTEXT_SVGTTF.get_fortytwo();

-- select * from HARFBUZZ_X.slabwidths_01;
-- select * from HARFBUZZ_X.slabwidths_jsonb;
-- select * from IPC.rpc( '^shyphenate', to_jsonb( 'one two'::text ) );
-- select * from HARFBUZZ_X.svgfont_01;
-- select substring( line from 1 for 100 ) from HARFBUZZ_X.get_svg_font_lines( 'f123' ) as r1 ( line );
-- select * from HARFBUZZ_X.fonts_and_paths where fid = 'f123';


-- select * from HARFBUZZ_X.slabwidths_01 order by vnr;
-- select * from HARFBUZZ_X.slabwidths_02 order by vnr;
-- select * from HARFBUZZ_X.slabwidths_03 order by vnr;
-- select * from HARFBUZZ_X.svglyphdefs;
-- select * from HARFBUZZ_X.linotype_preview( 'f123', 'helo' );

truncate LAZY.cache;
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 15 }———:reset
    -- insert into LAZY.cache ( bucket, key, value ) select
    --     'svgttf/pathdataplus'   as bucket,
    --     r2.key                  as key,
    --     r33.value::text          as value
    --   from generate_series( 1, 10 )      as r1 ( gid   )
    --   join HARFBUZZ_X.fonts_and_paths as r22 on r22.fid = 'f123',
    --   lateral jsonb_build_array( 'f123', r1.gid )       as r2 ( key   ),
    --   lateral INTERTEXT_SVGTTF.pathdataplus_from_glyphidx( r22.fontpath, r1.gid ) as r3 ( glyphname, chr, pathdata ),
    --   lateral ( select ( r3.glyphname, r3.chr, r3.pathdata )::INTERTEXT_SVGTTF.pathdataplus ) as r33 ( value )
    --   where not exists ( select 1 from LAZY.cache as r4
    --     where ( bucket = 'svgttf/pathdataplus' ) and ( r4.key = r2.key ) );
-- select
--     *
--   from INTERTEXT_SVGTTF.get_pathdataplus_lazy_speculative( 'f123', 123 )
--   ;
-- select * from LAZY.cache;

-- select
--     r1.fid                                  as fid,
--     r1.gid                                  as gid,
--     r1.glyphname                            as glyphname,
--     r1.chr                                  as chr,
--     substring( r1.pathdata from 1 for 50 )  as pathdata
--   from INTERTEXT_SVGTTF.cached_outlines as r1;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 20 }———:reset
create function INTERTEXT_SVGTTF._insert_fontmetrics( ¶fid text, ¶key text )
  returns void volatile strict language plpgsql as $$
  declare
  begin
    raise notice using message = format( 'INTERTEXT_SVGTTF._insert_fontmetrics( %L, %L )', ¶fid, ¶key );
    insert into LAZY.cache ( bucket, key, value ) select
        'svgttf/fontmetrics'    as bucket,
        r4.ckey                 as key,
        r3.mvalue::text         as value
      from HARFBUZZ_X.fonts_and_paths                                                         as r2,
      lateral jsonb_each( INTERTEXT_SVGTTF.metrics_from_fontpath( r2.fontpath ) )             as r3 ( mkey, mvalue ),
      lateral jsonb_build_array( 'f123', r3.mkey )                                            as r4 ( ckey   )
      where r2.fid = 'f123';
    end; $$;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 16 }———:reset
do $$
  begin perform LAZY.create_lazy_producer(
  function_name   => 'INTERTEXT_SVGTTF.get_fontmetrics_lazy',
  parameter_names => '{¶fid,¶key}',
  parameter_types => '{text,text}',
  return_type     => 'float',
  perform_update  => 'INTERTEXT_SVGTTF._insert_fontmetrics',
  bucket          => 'svgttf/fontmetrics' );
  end; $$;

-- create table MYSCHEMA.mycache (
--   n integer,
--   t text,
--   v float,
--   primary key ( n, t ) );

-- create view HARFBUZZ_T.MYVIEW as ( select 'myview' );
-- create view HARFBUZZ_T."MYVIEW" as ( select 'MYVIEW' );
-- select * from CATALOG.catalog where schema = 'harfbuzz_t' order by schema, name;
-- select pg_get_viewdef( 'harfbuzz_t."MYVIEW"' );
-- select pg_get_viewdef( 'harfbuzz_t.MYVIEW' );
-- select pg_get_viewdef( 'harfbuzz_t.myview' );
-- \quit

select * from HARFBUZZ_X.get_fontmetrics_lazy( 'f123', 'baseline' );
-- select * from HARFBUZZ_X.get_fontmetric( 'fxxx', 'baseline' );
select * from HARFBUZZ_X.fontmetrics;
select * from LAZY.cache;


select
        'svgttf/fontmetrics'    as bucket,
        r4.ckey                 as key,
        r3.mvalue::text         as value
      from HARFBUZZ_X.fonts_and_paths                                                         as r2,
      lateral jsonb_each( INTERTEXT_SVGTTF.metrics_from_fontpath( r2.fontpath ) )             as r3 ( mkey, mvalue ),
      lateral jsonb_build_array( 'f123', r3.mkey )                                            as r4 ( ckey   )
      where r2.fid = 'f123'
      ;



/* ###################################################################################################### */
\echo :red ———{ :filename 7 }———:reset
\quit




-- do $$ begin perform INVARIANTS.validate(); end; $$;

-- -- instead.








