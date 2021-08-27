

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
\set signal :blue

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
    fontpath  text not null );

insert into HARFBUZZ_X.fonts_and_paths ( fid, fontnick, fontpath ) values
  ( 'f456', 'fandolkai_regular_otf',  '/home/flow/jzr/hengist/assets/jizura-fonts/FandolKai-Regular.otf'  ),
  ( 'f455', 'hanamina_otf',           '/home/flow/jzr/hengist/assets/jizura-fonts/HanaMinA.otf'           ),
  ( 'f123', 'lmroman10_italic_otf',   '/home/flow/jzr/hengist/assets/jizura-fonts/lmroman10-italic.otf'   );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create table HARFBUZZ_X.fontmetrics (
    fid       text  not null,
    key       text  not null,
    value     float not null,
    primary key ( fid, key ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
create function HARFBUZZ_X.get_fontmetric( ¶fid text, ¶key text )
  returns float strict volatile language plpgsql as $$
  declare
    R           float;
    ¶row_count  integer;
    ¶hint       text;
  begin
    -- .....................................................................................................
    R := ( select value from HARFBUZZ_X.fontmetrics where fid = ¶fid and key = ¶key );
    if R is not null then return R; end if;
    -- .....................................................................................................
    insert into HARFBUZZ_X.fontmetrics ( fid, key, value ) ( select
        r1.fid                          as fid,
        r2.key                          as key,
        ( r2.value#>>'{}' )::float      as value
      from HARFBUZZ_X.fonts_and_paths                                             as r1,
      lateral jsonb_each( INTERTEXT_SVGTTF.metrics_from_fontpath( r1.fontpath ) ) as r2 ( key, value )
      where r1.fid = ¶fid );
    -- .....................................................................................................
    get diagnostics ¶row_count = row_count;
    if ¶row_count = 0 then
      ¶hint := format( 'unable to retrieve font metrics for font with FID %s', ¶fid );
      raise sqlstate 'HBX01' using message = '#HBX01-1 Value Error', hint = ¶hint;
      end if;
    -- .....................................................................................................
    R := ( select value from HARFBUZZ_X.fontmetrics where fid = ¶fid and key = ¶key );
    if R is not null then return R; end if;
    -- .....................................................................................................
    ¶hint := format( 'font FID %s has no metric named %s', ¶fid, ¶key );
    raise sqlstate 'HBX02' using message = '#HBX02-1 Key Error', hint = ¶hint;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
create table HARFBUZZ_X.slabwidths_01 as ( select
    r2.vnr    as vnr,
    r2.slab   as slab,
    r2.joint  as joint
  -- from 'supercoherent amazingly eloquent fi'::text as r1 ( line ),
  -- from ( select 'one two three'::text ) as r1 ( line ),
  from ( select 'Ulysses Atlantis Primordial'::text ) as r1 ( line ),
  lateral INTERTEXT_SLABS.shyphenate( r1.line ) as r2
  order by vnr
  -- , lateral ( select 42 ) as d2 ( x )
  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
/* insert pseudo-slabs with joint `+` to represent slabs separated by spaces: */
insert into HARFBUZZ_X.slabwidths_01 ( select
    VNR.cat( r1.vnr, VNR.greatest() ) as vnr,
    null                              as slab,
    '+'                               as joint
  from HARFBUZZ_X.slabwidths_01 as r1
  where r1.joint = '°' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 7 }———:reset
/* insert pseudo-slab with joint `T` to represent the (width of) the slug: */
insert into HARFBUZZ_X.slabwidths_01 ( vnr, slab, joint ) values ( VNR.greatest(), null, 'T' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 8 }———:reset
/* create table with all slabs resolved into segments with typographical metrics; this will omit all
  pseudo-segments where `slab` is `null` b/c we're calling a `strict` function: */
create table HARFBUZZ_X.slabwidths_02 as ( select
    r4.vnr                                as vnr,
    r1.slab                               as slab,
    r1.joint                              as joint,
    r3.fid                                as fid,
    r3.gid                                as gid,
    r3.dx                                 as width,
    null::float                           as x
  from HARFBUZZ_X.slabwidths_01                                                   as r1,
  lateral ( select fontpath from HARFBUZZ_X.fonts_and_paths where fid = 'f123' )  as r12,
  lateral HARFBUZZ.metrics_from_text_as_rows( r12.fontpath, r1.slab )             as r3,
  lateral VNR.cat( r1.vnr, r3.vnr )                                               as r4 ( vnr )
  order by vnr );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
/* Supply missing widths for pseudo-segments representing spaces (with assumed arbitrary widths) and the entry
  representing the slug (with width `null`):*/
insert into HARFBUZZ_X.slabwidths_02 ( select
    r1.vnr                                          as vnr,
    r1.slab                                         as slab,
    r1.joint                                        as joint,
    null                                            as fid,
    null                                            as gid,
    case r1.joint when '+' then 250 else null end   as width,
    null                                            as x
  from HARFBUZZ_X.slabwidths_01 as r1 where r1.joint in ( '+', 'T' ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
/* Supply current `x` position for each element which computes as the cumulative widths for each glyf,
  excluding the current one: */
update HARFBUZZ_X.slabwidths_02 as ro set x = coalesce( ri.cumulative_width, 0 ) from ( select
    vnr,
    sum( width ) over w as cumulative_width
  from HARFBUZZ_X.slabwidths_02
  window w as ( order by vnr
    range between unbounded preceding and current row
    exclude current row ) ) as ri
  where ro.vnr = ri.vnr;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 11 }———:reset
-- ### TAINT use XML schema methods ###
create function HARFBUZZ_X._svg_document_opener( ¶minx float, ¶miny float, ¶width float, ¶height float )
  returns text strict immutable language sql as $$
  select format(
    '<?xml version=''1.0'' standalone=''no''?>' ||
    '<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''%s %s %s %s''>', ¶minx, ¶miny, ¶width, ¶height ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 12 }———:reset
-- ### TAINT use XML schema methods ###
create function HARFBUZZ_X._svg_use_symbol( ¶x float, ¶fid text, ¶gid integer )
  returns text strict immutable language sql as $$
  -- <text x='10' y='0' textLength='14700' style='font-size:1000;fill:#0005'>o tempores o mores Qualificandur</text>
  select format( '<use x=''%s'' y=''0'' href="/v2/font?fid=%s#g%s"/>', ¶x, ¶fid, ¶gid ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 13 }———:reset
-- ### TAINT use XML schema methods ###
-- ### NOTE should allow subsetting ###
-- ### TAINT use `pathdataplus` as argument ###
-- ### TAINT shouldn't ¶gid be an integer? (or a text including the leading `g`?) ###
create function HARFBUZZ_X._svg_def_symbol( ¶fid text, ¶gid float, ¶glyphname text, ¶chr text, ¶pathdata text )
  returns text strict immutable language plpgsql as $$
  declare
    ¶baseline     float;
    ¶cell_width   integer := 1000;
    ¶cell_height  integer := 1000;
    ¶grid_width   integer := 64;
    ¶x0           integer := 0;
    ¶y0           integer := 0;
    ¶x            integer := 0;
    ¶y            integer := 0;
  begin
    ¶x        := ¶x0 + ( ¶cell_width  * ( ¶gid::integer % ¶grid_width ) );
    ¶y        := ¶y0 + ( ¶cell_height * ( ¶gid::integer / ¶grid_width ) );
    ¶baseline := ( select * from HARFBUZZ_X.get_fontmetric( ¶fid, 'baseline' ) );
    return format(
      '<g transform=''scale(0.1) translate(%s,%s)''>' ||
      '<!-- %s %s -->' ||
      /* ### NOTE `translate()` is there to adjust for font baseline; this should come from opentype.js */
      '<path transform=''translate(0,%s)'' id=''g%s'' d=''%s''/>' ||
      '</g>',
      ¶x, ¶y,
      ¶glyphname,
      XML.escape_text( ¶chr ),
      ¶baseline,
      ¶gid,
      ¶pathdata );
    end; $$;
    -- select format(
    --   '<!-- %s -->' ||
    --   '<symbol id=''g%s'' width=''1000'' height=''1800'' viewBox=''0,-800,1000,1000''>' ||
    --   '<path d=''%s''/>' ||
    --   '</symbol>',
    --   ¶glyphname,
    --   ¶gid,
    --   ¶pathdata ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 14 }———:reset
create view HARFBUZZ_X.slabwidths_03 as ( select
    r1.vnr          as vnr,
    r1.slab         as slab,
    r1.joint        as joint,
    r1.fid          as fid,
    r1.gid          as gid,
    r1.width        as width,
    r1.x            as x,
    r2.svglyphref   as svglyphref
  from HARFBUZZ_X.slabwidths_02                               as r1,
  lateral HARFBUZZ_X._svg_use_symbol( r1.x, r1.fid, r1.gid )  as r2 ( svglyphref )
  order by vnr );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 15 }———:reset
create view HARFBUZZ_X.svglyphdefs as ( select
    r2.fid          as fid,
    r1.gid          as gid,
    r3.glyphname    as glyphname,
    r3.chr          as chr,
    r4.svglyphdef   as svglyphdef
    -- r3.pathdata     as pathdata
    -- r2.fontpath     as fontpath
  from
    -- generate_series( 0, 1024 )                                                      as r1 ( gid ),
    generate_series( 0, 123 )                                                               as r1 ( gid ),
    HARFBUZZ_X.fonts_and_paths                                                              as r2,
    lateral INTERTEXT_SVGTTF.pathdataplus_from_glyphidx( r2.fontpath, r1.gid )              as r3,
    lateral HARFBUZZ_X._svg_def_symbol( r2.fid, r1.gid, r3.glyphname, r3.chr, r3.pathdata ) as r4 ( svglyphdef )
    where true
      and ( r2.fid = 'f123'         )
      and ( r3.pathdata is not null )
      and ( r3.pathdata != ''       )
    );
    -- XML.escape_text( ¶chr )
    -- '<text x=''10'' y=''0'' textLength=''1000'' style=''font-size:1000;fill:yellow;''>%s</text>' ||

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 16 }———:reset
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
        return next XML.tag( '{"$key":"<tag","name":"text","atrs":{"x":30,"y":30}}' );
        return next XML.escape_text( 'SVG symbol font for ' || ¶fontnick );
        return next XML.tag( '{"$key":">tag","name":"text"}' );
        -- ### TAINT use function call instead of select ###
        for ¶svg_row in ( select * from HARFBUZZ_X.svglyphdefs order by gid ) loop
          return next ¶svg_row.svglyphdef;
          end loop;
        return next substring( ¶template_row.line from ¶nr + ¶marker_length );
        end if;
      end loop;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 17 }———:reset
-- ### NOTE should allow subsetting ###
create function HARFBUZZ_X.linotype_preview( ¶fid text, ¶text text )
  returns setof text strict immutable language plpgsql as $$
  declare
    ¶width  float := 0;
    ¶height float := 0;
    ¶row    record;
  begin
    ¶width  := ( select x from HARFBUZZ_X.slabwidths_03 where vnr = array[ 'infinity'::float ] );
    -- ### TAINT base ¶height on font properties
    ¶height := 1200;
    return next HARFBUZZ_X._svg_document_opener( 0, 0, ¶width, ¶height );
    for ¶row in ( select * from HARFBUZZ_X.slabwidths_03 ) loop
      return next ¶row.svglyphref;
      end loop;
    return next '</svg>';
    --   ¶nr := position( ¶marker in ¶template_row.line );
    --   if ¶nr = 0 then
    --     return next ¶template_row.line;
    --   else
    --     return next substring( ¶template_row.line from 1 for ¶nr - 1 );
    --     -- ### NOTE observe crazy syntax here, `"text"` is an SQL identifier, `name text` gives `<text ...>` ###
    --     return next XML.tag( '{"$key":"<tag","name":"text","atrs":{"x":30,"y":30}}' );
    --     return next XML.escape_text( 'SVG symbol font for' || ¶fontnick || '.' );
    --     return next XML.tag( '{"$key":">tag","name":"text"}' );
    --     -- ### TAINT use function call instead of select ###
    --     for ¶svg_row in ( select * from HARFBUZZ_X.svglyphdefs order by gid ) loop
    --       return next ¶svg_row.svglyphdef;
    --       end loop;
    --     return next substring( ¶template_row.line from ¶nr + ¶marker_length );
    --     end if;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 18 }———:reset
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

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 19 }———:reset
-- -- create view HARFBUZZ_X.svgfont_02 as ( select
-- --     *
-- --   from HARFBUZZ_X.svgfont_01 as r1,
-- --   lateral string_agg( )
-- --   lateral regexp_replace( r1.line, '\$\{symboldefs\}', )
-- -- )

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 20 }———:reset
create function INTERTEXT_SVGTTF._insert_pathdataplus( ¶fid text, ¶gid integer )
  returns void volatile strict language plpgsql as $$ declare
    ¶glyphname text;
    ¶chr       text;
    ¶pathdata  text;
  begin
    raise notice 'INTERTEXT_SVGTTF._insert_pathdataplus( %, % )', ¶fid, ¶gid;
    insert into LAZY.cache ( bucket, key, value ) select
        'svgttf/pathdataplus'   as bucket,
        r3.key                  as key,
        r5.value::text          as value
      from generate_series( ¶gid - 50, ¶gid + 50 )                                            as r1 ( gid   )
      join HARFBUZZ_X.fonts_and_paths                                                         as r2
        on r2.fid = ¶fid,
      lateral jsonb_build_array( ¶fid, r1.gid )                                               as r3 ( key   ),
      lateral INTERTEXT_SVGTTF.pathdataplus_from_glyphidx( r2.fontpath, r1.gid )              as r4 ( glyphname, chr, pathdata ),
      lateral ( select ( r4.glyphname, r4.chr, r4.pathdata )::INTERTEXT_SVGTTF.pathdataplus ) as r5 ( value )
      where not exists ( select 1 from LAZY.cache                                             as r6
        where ( bucket = 'svgttf/pathdataplus' ) and ( r6.key = r3.key ) );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 16 }———:reset
do $$
  begin perform LAZY.create_lazy_producer(
  function_name   => 'INTERTEXT_SVGTTF.get_pathdataplus_lazy_speculative',
  parameter_names => '{¶fid,¶gid}',
  parameter_types => '{text,integer}',
  return_type     => 'INTERTEXT_SVGTTF.pathdataplus',
  perform_update  => 'INTERTEXT_SVGTTF._insert_pathdataplus',
  bucket          => 'svgttf/pathdataplus' );
  end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create view INTERTEXT_SVGTTF.cached_outlines as ( select
      key->>0               as fid,
      key->>1::integer      as gid,
      (r2.value).glyphname  as glyphname,
      (r2.value).chr        as chr,
      (r2.value).pathdata   as pathdata
    from LAZY.cache                                             as r1,
    lateral ( select r1.value::INTERTEXT_SVGTTF.pathdataplus )  as r2
    where bucket = 'svgttf/pathdataplus'
    order by fid, glyphname, gid );



/* ###################################################################################################### */
\echo :red ———{ :filename 22 }———:reset
\quit



