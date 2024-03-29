
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP-INTERTEXT/RPC'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# types                     = ( require 'intershop' ).types
# { isa
#   validate
#   cast
#   type_of }               = types.export()
SVGTTF                    = require 'svgttf'

#-----------------------------------------------------------------------------------------------------------
cache =
  fonts_by_paths: {}

#-----------------------------------------------------------------------------------------------------------
font_from_path = ( path ) ->
  return R if ( R = cache.fonts_by_paths[ path ] )?
  whisper "^347^ reading font #{path}"
  R = cache.fonts_by_paths[ path ] = SVGTTF.font_from_path path
  urge "^347^ read font #{path} with #{R.otjsfont.numGlyphs} outlines"
  return R

#-----------------------------------------------------------------------------------------------------------
@get_fortytwo = ( P... ) ->
  debug '^intershop-intertext/get_fortytwo@44556^', { P, }
  return P.reduce ( ( acc, x ) -> acc + x ), 42

#-----------------------------------------------------------------------------------------------------------
@pathdata_from_glyphidx = ( fontpath, glyphidx ) ->
  # debug '^intershop-intertext/get_fortytwo@44556^', { fontpath, glyphidx, }
  # T.eq ( SVGTTF.pathelement_from_glyphidx font, 23, 1000, [ [ 'translate', [ 100, ], ], ] ), "<path transform='translate(100)' d='M373-631C373-652 368-694 325-694C285-694 260-659 260-630C260-598 283-588 304-588C321-588 339-597 349-607C338-547 300-476 234-422C221-410 220-409 220-405C220-402 223-395 230-395C249-395 373-514 373-631Z'/>"
  return SVGTTF.pathdata_from_glyphidx ( font_from_path fontpath ), glyphidx

#-----------------------------------------------------------------------------------------------------------
@pathelement_from_glyphidx = ( fontpath, glyphidx ) ->
  size      = 1000
  transform = null
  return SVGTTF.pathelement_from_glyphidx ( font_from_path fontpath ), glyphidx, size, transform

#-----------------------------------------------------------------------------------------------------------
@pathdataplus_from_glyphidx = ( fontpath, glyphidx ) ->
  size      = 1000
  transform = null
  return SVGTTF.pathdataplus_from_glyphidx ( font_from_path fontpath ), glyphidx, size, transform

#-----------------------------------------------------------------------------------------------------------
@metrics_from_fontpath = ( fontpath ) ->
  return SVGTTF.get_metrics ( font_from_path fontpath )







