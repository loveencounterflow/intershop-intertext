

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


/* ###################################################################################################### */
\echo :red ———{ :filename 7 }———:reset
\quit




-- do $$ begin perform INVARIANTS.validate(); end; $$;

-- -- instead.








