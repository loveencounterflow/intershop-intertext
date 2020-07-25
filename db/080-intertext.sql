


/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
\set filename interplot/db/080-intertext.sql
\set signal :green
\set ECHO none

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists INTERTEXT       cascade; create schema INTERTEXT;
drop schema if exists INTERTEXT_HYPH  cascade; create schema INTERTEXT_HYPH;
drop schema if exists INTERTEXT_SLABS cascade; create schema INTERTEXT_SLABS;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
-- thx to https://stackoverflow.com/a/31757242/7568091
create function INTERTEXT.as_text( jsonb )
  returns text strict immutable parallel safe language sql as $$
  select $1#>>'{}'; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create function INTERTEXT_HYPH.hyphenate( ¶text text )
  returns text strict immutable language sql as $$
  select IPC.rpc( '^hyphenate', to_jsonb( ¶text ) )::text; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
create function INTERTEXT_HYPH.reveal_hyphens( ¶text text )
  returns text strict immutable language sql as $$
  select regexp_replace( ¶text, u&'\00ad', '-', 'g' ) ; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
create function INTERTEXT_HYPH.reveal_hyphenate( ¶text text )
  returns text strict immutable language sql as $$
  select INTERTEXT_HYPH.reveal_hyphens( INTERTEXT_HYPH.hyphenate( ¶text ) ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
create function INTERTEXT_SLABS.slabjoints_from_text( ¶text text )
  returns jsonb strict immutable language sql as $$
  select IPC.rpc( '^slabjoints_from_text', to_jsonb( ¶text ) ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 7 }———:reset
create type INTERTEXT_SLABS.slabjoint as (
    vnr   VNR.vnr,
    slab  text,
    joint text );

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 8 }———:reset
-- create function INTERTEXT_SLABS.slabjoints_from_jsonb( ¶slabjoint jsonb )
--   returns setof INTERTEXT_SLABS.slabjoint strict immutable language plpgsql as $$
--   declare
--     ¶slabs      jsonb;
--     ¶joints     text;
--   begin
--     ¶slabs      :=  ¶slabjoint->'slabs';
--     ¶joints     :=  ¶slabjoint->>'ends';
--     for ¶idx in 0 .. jsonb_array_length( ¶slabs ) - 1 loop
--       return next ( ¶slabs->>¶idx, substring( ¶joints from ¶idx + 1 for 1 ) )::INTERTEXT_SLABS.slabjoint;
--       end loop;
--     end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
create function INTERTEXT_SLABS.slabjoints_from_jsonb( ¶slabjoint jsonb )
  returns setof INTERTEXT_SLABS.slabjoint strict immutable language plpgsql as $$
  declare
    ¶segments     jsonb;
    ¶segment      text;
    R             INTERTEXT_SLABS.slabjoint;
  begin
    ¶segments :=  ¶slabjoint->'segments';
    for ¶idx in 0 .. jsonb_array_length( ¶segments ) - 1 loop
      ¶segment  :=  ¶segments->>¶idx;
      R.vnr     := array[ ¶idx + 1 ];
      R.slab    := substring( ¶segment for length( ¶segment ) - 1 );
      R.joint   := substring( ¶segment from length( ¶segment ) );
      return next R;
      end loop;
    end; $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 10 }———:reset
-- create function INTERTEXT_SLABS.shyphenate( ¶text text )
--   returns setof INTERTEXT_SLABS.slabjoint strict immutable language sql as $$
--   select * from INTERTEXT_SLABS.slabjoints_from_jsonb( IPC.rpc( '^shyphenate', to_jsonb( ¶text ) ) ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 11 }———:reset
create function INTERTEXT_SLABS.shyphenate( ¶text text )
  returns setof INTERTEXT_SLABS.slabjoint strict immutable language sql as $$
  select * from INTERTEXT_SLABS.slabjoints_from_jsonb( IPC.rpc( '^shyphenate', to_jsonb( ¶text ) ) ); $$;


-- #-----------------------------------------------------------------------------------------------------------
-- @assemble = ( me, first_idx = null, last_idx = null ) ->
--   ### TAINT validate indexes? ###
--   first_idx  ?= 0
--   last_idx   ?= me.slabs.length - 1
--   first_idx   = Math.max first_idx, 0
--   last_idx    = Math.min last_idx, me.slabs.length - 1
--   R           = ''
--   #.........................................................................................................
--   for idx in [ first_idx .. last_idx ] by +1
--     R += me.slabs[ idx ]
--     switch end = me.ends[ idx ]
--       when 'x'  then null
--       when '_'  then ( if idx isnt last_idx then R+= '\x20' )
--       ### TAINT allow to configure hyphen ###
--       when '|'  then ( if idx is last_idx then R+= '-' )
--       else throw new Error "^INTERTEXT/SLABS@4352^ unknown slab `end` option #{rpr end}"
--   #.........................................................................................................
--   return R

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 12 }———:reset


/* ###################################################################################################### */
\echo :red ———{ :filename 13 }———:reset
\quit






