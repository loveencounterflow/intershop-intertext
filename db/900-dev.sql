

-- \set ECHO queries

/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
-- ---------------------------------------------------------------------------------------------------------
-- \set filename interplot/db/tests/080-intertext.sql
\set filename interplot/db/900-dev.sql
\set signal :red

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists HARFBUZZ_X cascade; create schema HARFBUZZ_X;


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create table HARFBUZZ_X.fonts_and_paths (
    fid       text not null unique primary key,
    fontnick  text not null,
    path      text not null );

insert into HARFBUZZ_X.fonts_and_paths ( fid, fontnick, path ) values
  ( 'f456', 'fandolkai_regular_otf',  '/home/flow/jzr/hengist/assets/jizura-fonts/FandolKai-Regular.otf'  ),
  ( 'f455', 'hanamina_otf',           '/home/flow/jzr/hengist/assets/jizura-fonts/HanaMinA.otf'           ),
  ( 'f123', 'lmroman10_italic_otf',   '/home/flow/jzr/hengist/assets/jizura-fonts/lmroman10-italic.otf'   );


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create view HARFBUZZ_X.slabwidths_01 as ( select
    r1.vnr    as vnr,
    r1.slab   as slab,
    r1.joint  as joint
  from INTERTEXT_SLABS.shyphenate( 'supercoherent amazingly eloquent fi'::text ) as r1
  order by vnr
  -- , lateral ( select 42 ) as d2 ( x )
  );

-- insert into HARFBUZZ_X.slabwidths_01 ( vnr, slab, joint ) values
--   ( '{1,1}', 'amazingly', '°' ),
--   ( '{3,1}', 'eloquent', '°' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
create view HARFBUZZ_X.slabwidths_jsonb as ( select
    r1.vnr        as vnr,
    r1.slab       as slab,
    r1.joint      as joint,
    r3.width      as width
  from HARFBUZZ_X.slabwidths_01                      as r1,
  -- lateral ( select '/home/flow/jzr/hengist/assets/jizura-fonts/FandolKai-Regular.otf' as font_path ) as r12,
  lateral ( select '/home/flow/jzr/hengist/assets/jizura-fonts/lmroman10-italic.otf' as font_path ) as r12,
  lateral HARFBUZZ.metrics_from_text_as_jsonb( r12.font_path, r1.slab )  as r3 ( width )
  -- lateral to_char( d2.width, '99,990.000' )                 as r3 ( width )
  order by vnr );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
create view HARFBUZZ_X.slabwidths_02 as ( select
    r4.vnr                                as vnr,
    r1.slab                               as slab,
    r1.joint                              as joint,
    r3.fid                                as fid,
    r3.gid                                as gid,
    r3.dx                                 as width,
    coalesce( lag( r3.dx ) over w1, 0 )   as next_dx
  from HARFBUZZ_X.slabwidths_01                                                                     as r1,
  -- lateral ( select '/home/flow/jzr/hengist/assets/jizura-fonts/FandolKai-Regular.otf' as font_path ) as r12,
  lateral ( select '/home/flow/jzr/hengist/assets/jizura-fonts/lmroman10-italic.otf' as font_path ) as r12,
  lateral HARFBUZZ.metrics_from_text_as_rows( r12.font_path, r1.slab )                              as r3,
  lateral VNR.cat( r1.vnr, r3.vnr )                                                                 as r4 ( vnr )
  window w1 as ( order by r4.vnr rows between unbounded preceding and current row )
  order by vnr );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
create view HARFBUZZ_X.slabwidths_03 as (
  ( select * from HARFBUZZ_X.slabwidths_02 ) union all
  ( select
      VNR.greatest()  as vnr,
      null            as slab,
      null            as joint,
      null            as fid,
      null            as gid,
      null            as width,
      r1.width        as next_dx
    from HARFBUZZ_X.slabwidths_02 as r1
    order by vnr desc limit 1 ) );

comment on view HARFBUZZ_X.slabwidths_03 is 'Same as HARFBUZZ_X.slabwidths_02 but with one row added to take
up the width of the last glyph to be typeset, so the last instance of the running sum in
HARFBUZZ_X.slabwidths_04.x can represent the width of the entire line of type.';

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 7 }———:reset
create view HARFBUZZ_X.slabwidths_04 as ( select
    r1.vnr          as vnr,
    r1.slab         as slab,
    r1.joint        as joint,
    r1.fid          as fid,
    r1.gid          as gid,
    r1.width        as width,
    r1.next_dx      as next_dx,
    sum( r1.next_dx ) over w1                  as x
  from HARFBUZZ_X.slabwidths_03 as r1
  window w1 as ( order by r1.vnr rows between unbounded preceding and current row )
  order by vnr );

comment on view HARFBUZZ_X.slabwidths_04 is 'Same as HARFBUZZ_X.slabwidths_03 but with a running sum of the
widths of the glyphs; the sum in the line with the VNR `{infinity}` represents the width of the entire line
of type.';

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 8 }———:reset
-- ### TAINT use Postgres XML datatype, functions ###
create function HARFBUZZ_X._svg_use_symbol( ¶x float, ¶fid text, ¶gid integer )
  returns text strict immutable language sql as $$
    select format( '<use x=''%s'' y=''0'' href="f/%s#g%s"/>', ¶x, ¶fid, ¶gid ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
-- ### TAINT use Postgres XML datatype, functions ###
-- ### NOTE should allow subsetting ###
create function HARFBUZZ_X._svg_def_symbol( ¶fid text, ¶gid float, ¶glyphname text, ¶pathdata text )
  returns text strict immutable language sql as $$
    select format(
      '<!-- %s --><symbol id=''g%s'' viewBox=''0,0,1000,1000''><path d=''%s''/></symbol>',
      ¶glyphname,
      ¶gid,
      -- ¶fid,
      ¶pathdata ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
create view HARFBUZZ_X.slabwidths_05 as ( select
    r1.vnr          as vnr,
    r1.slab         as slab,
    r1.joint        as joint,
    r1.fid          as fid,
    r1.gid          as gid,
    r1.width        as width,
    r1.next_dx      as next_dx,
    r1.x            as x,
    r2.svglyphref   as svglyphref
  from HARFBUZZ_X.slabwidths_04                               as r1,
  lateral HARFBUZZ_X._svg_use_symbol( r1.x, r1.fid, r1.gid )  as r2 ( svglyphref )
  where r1.gid is not null
  order by vnr );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 11 }———:reset
create view HARFBUZZ_X.svglyphdefs as ( select
    r2.fid          as fid,
    r1.gid          as gid,
    r3.glyphname    as glyphname,
    r4.svglyphdef   as svglyphdef
    -- r3.pathdata     as pathdata
    -- r2.path         as fontpath
  from
    generate_series( 10, 20 )                                                      as r1 ( gid ),
    -- generate_series( 0, 1024 )                                                      as r1 ( gid ),
    HARFBUZZ_X.fonts_and_paths                                                      as r2,
    lateral INTERTEXT_SVGTTF.pathdataplus_from_glyphidx( r2.path, r1.gid )          as r3 ( pathdata, glyphname ),
    lateral HARFBUZZ_X._svg_def_symbol( r2.fid, r1.gid, r3.glyphname, r3.pathdata ) as r4 ( svglyphdef )
    where true
      and ( r2.fid = 'f123'         )
      and ( r3.pathdata is not null )
      and ( r3.pathdata != ''       )
    );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 12 }———:reset
-- ### NOTE should allow subsetting ###
create function HARFBUZZ_X.get_svg_font_lines( ¶fid text )
  returns setof text strict immutable language plpgsql as $$
  declare
    ¶marker         text    :=  '${symboldefs}';
    ¶marker_length  integer :=  character_length( ¶marker );
    ¶nr             integer;
    ¶template_row   record;
    ¶svg_row        record;
    ¶fontnick       text;
  begin
    select fontnick from HARFBUZZ_X.fonts_and_paths where fid = ¶fid limit 1 into ¶fontnick;
    for ¶template_row in ( select * from HARFBUZZ_X.svgfont_01 ) loop
      ¶nr := position( ¶marker in ¶template_row.line );
      if ¶nr = 0 then
        return next ¶template_row.line;
      else
        return next substring( ¶template_row.line from 1 for ¶nr - 1 );
        -- ### NOTE observe crazy syntax here, `"text"` is an SQL identifier, `name text` gives `<text ...>` ###
        return next xmlelement(
          name "text",
          xmlattributes( 100 as x, 100 as y ),
          'SVG symbol font for' || ¶fontnick || '.' )::text || '\n';
        -- ### TAINT use function call instead of select ###
        for ¶svg_row in ( select * from HARFBUZZ_X.svglyphdefs order by gid ) loop
          return next ¶svg_row.svglyphdef;
          end loop;
        return next substring( ¶template_row.line from ¶nr + ¶marker_length );
        end if;
      end loop;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 13 }———:reset
create view HARFBUZZ_X.svgfont_01 as ( select
    r1.linenr as linenr,
    r2.line   as line
  from MIRAGE.mirror as r1,
  lateral regexp_replace( r1.line, '<!--@ignore.*-->', '' ) as r2 ( line )
  where true
    and r1.include
    and ( r1.dsk = 'symboldefs' )
    and ( r2.line != '' )
  order by r1.dsnr, r1.linenr );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 14 }———:reset
-- create view HARFBUZZ_X.svgfont_02 as ( select
--     *
--   from HARFBUZZ_X.svgfont_01 as r1,
--   lateral string_agg( )
--   lateral regexp_replace( r1.line, '\$\{symboldefs\}', )
-- )



/* ###################################################################################################### */
\echo :red ———{ :filename 7 }———:reset
\quit



