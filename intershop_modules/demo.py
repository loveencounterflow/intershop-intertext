#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys        as _SYS
import getpass    as _GETPASS
import os         as _OS
import json       as _JSON
# import uharfbuzz  as HB

#-----------------------------------------------------------------------------------------------------------
def f( ctx ):
   # ~/.local/lib/python3.6/site-packages/
  username = _GETPASS.getuser()
  homedir = _OS.path.expanduser("~")
  ctx.log( '^3397745^', "__file__:", __file__ )
  ctx.log( '^3397745^', "_OS.path.basename( __file__ ):", _OS.path.basename( __file__ ) )
  ctx.log( '^3397745^', "_OS.path.dirname( __file__ ):", _OS.path.dirname( __file__ ) )
  ctx.log( '^3397745^', "_OS.path.expanduser( '~/.local' ):", _OS.path.expanduser( '~/.local' ) )
  ctx.log( '^3397745^', "username:", username )
  ctx.log( '^3397745^', "homedir:", homedir )
  ctx.log( '^3397745^', "_SYS.executable:", _SYS.executable )
  # ctx.log( '^3397745^', "ctx:", ctx )
  # for key, value in ctx:
  #   ctx.log( '^3397745^', { 'key': key, 'value': value, } )
  ctx.log( '^3397745^', "list( k for k in ctx ):", list( k for k in ctx ) )
  ctx.log( '^3397745^', "ctx.get_variable( 'intershop/host/bin/path'):", ctx.get_variable( 'intershop/host/bin/path') )
  # ctx.log( '^3397745^', "ctx.uharfbuzz_path:", ctx.uharfbuzz_path )
  # ctx.log( '^3397745^', "ctx.get_variable_names():", ctx.get_variable_names() )
  # ctx.log( '^3397745^', "ctx.get_variable( 'uharfbuzz/path' ):", ctx.get_variable( 'uharfbuzz/path' ) )
  ctx.log( '\u4e01' + _JSON.dumps( { '$key': '^rpc', } ) )
  #.........................................................................................................
  ctx.log( '^22787^', "ctx.addons:", ctx.addons )
  # for path in _SYS.path:
  #   ctx.log( '^2221^', '-->', path )
  #.........................................................................................................
  # import uharfbuzz

