

-- \set ECHO queries

/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
-- ---------------------------------------------------------------------------------------------------------
-- \set filename interplot/db/tests/080-intertext.sql
\set filename interplot/db/070-xml.sql
\set signal :green

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists XML cascade; create schema XML;


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function XML.escape_text( text ) returns text strict immutable language plpgsql as $$
  declare
   R text;
  begin
    R := $1;
    R := regexp_replace( R, '&', '&amp;', 'g' );
    R := regexp_replace( R, '<', '&lt;',  'g' );
    R := regexp_replace( R, '>', '&gt;',  'g' );
    return R; end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function XML.escape_attribute_value( text ) returns text strict immutable language plpgsql as $$
  declare
   R text;
  begin
    R := XML.escape_text( $1 );
    R := regexp_replace( R, '''', '&#39;', 'g' );
    R := regexp_replace( R, '\n', '&#10;', 'g' );
    R := '''' || R || '''';
    return R; end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function XML.as_attribute( ¶name text, ¶value text ) returns text strict immutable language sql as $$
  -- ### TAINT consider to validate name ###
  select ¶name || '=' || XML.escape_attribute_value( ¶value ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function XML.as_attributes( jsonb ) returns text strict immutable language sql as $$
  select string_agg( XML.as_attribute( key, value ), ' ' ) from jsonb_each_text( $1 ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function XML._tag( ¶d jsonb, ¶slash boolean default false )
  returns text strict immutable language plpgsql as $$
  declare
    ¶hint   text;
    ¶atrs   jsonb;
    ¶suffix text;
  begin
    case ¶d->>'$key'
      when '<tag' then
        ¶atrs := ¶d->'atrs';
        if ¶slash then ¶suffix := '/>'; else ¶suffix := '>'; end if;
        if ¶atrs is null then
          return '<' || ( ¶d->>'name' ) || ¶suffix;
        else
          return '<' || ( ¶d->>'name' ) || ' ' || XML.as_attributes( ¶d->'atrs' ) || ¶suffix;
          end if;
      when '^tag' then
        if ( ¶d->'short' ) = 'true'::jsonb then
          return XML._tag( jsonb_set( ¶d, '{$key}', '"<tag"' ), true );
        else
          return XML._tag( jsonb_set( ¶d, '{$key}', '"<tag"' ) ) || XML._tag( jsonb_set( ¶d, '{$key}', '">tag"' ) );
          end if;
      when '>tag' then
        return '</' || ( ¶d->>'name' ) || '>';
      else
        ¶hint := format( 'expected JSON object with $key being one of ''^tag'', ''<tag'', or ''>tag'', got %s', ¶d );
        raise sqlstate 'XML01' using message = '#XML01-5 Value Error', hint = ¶hint;
        end case;
    -- return '';
    end; $$;

create function XML.tag( ¶d jsonb ) returns text strict immutable language sql as $$
  select XML._tag( ¶d, false ); $$;

comment on function XML.tag( jsonb ) is '

```
{ ''$key'': ''<tag'', name: ''article'', type: ''otag'', text: ''<article foo=yes>'', start: 0, stop: 17, atrs: { foo: ''yes'' }, ''$vnr'', }
```
';


/* ###################################################################################################### */
\echo :red ———{ :filename 7 }———:reset
\quit



