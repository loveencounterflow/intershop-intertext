(function() {
  'use strict';
  var CND, CP, FS, PATH, alert, badge, create_symlink, debug, echo, get_path_to_python_site_packages, get_symlink_path, help, info, log, rpr, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'INTERSHOP-INTERTEXT/POSTINSTALL';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  FS = require('fs');

  PATH = require('path');

  CP = require('child_process');

  //-----------------------------------------------------------------------------------------------------------
  get_path_to_python_site_packages = function() {
    var R, cmd, error, patterns, settings;
    whisper("^77762-1^ trying to find path to Python site-packages");
    // cmd       = [ 'python3.6', '-c', "import uharfbuzz as d; print( d.__path__[ 0 ] )" ]
    cmd = 'python3.6 -c "import uharfbuzz as d; print( d.__path__[ 0 ] )"';
    patterns = {
      module_not_found: /ModuleNotFoundError: No module named /
    };
    settings = {
      shell: false,
      encoding: 'utf-8'
    };
    try {
      R = CP.execSync(cmd, settings);
    } catch (error1) {
      error = error1;
      if (patterns.module_not_found.test(error.message)) {
        warn(CND.reverse("^77762-2^ unable to find required Python module"));
        urge(CND.reverse("^77762-3^ run `pip install uharfbuzz` (or, better, `pip3.6 install uharfbuzz`)"));
        urge(CND.reverse("^77762-4^ to install the dependency and try again to `npm install intershop-intertext`"));
      }
      throw error;
    }
    R = R.replace(/\n+$/, '');
    help(`^77762-5^ found path to Python site-packages: ${rpr(R)}`);
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  get_symlink_path = function() {
    return PATH.join(__dirname, '../intershop_modules/uharfbuzz');
  };

  //-----------------------------------------------------------------------------------------------------------
  create_symlink = function(path_source, path_target) {
    var error, path_source_rel;
    path_source_rel = PATH.relative(process.cwd(), path_source);
    whisper(`^77762-6^ trying to create symlink at ${path_source_rel} to Python site-packages`);
    try {
      FS.symlinkSync(path_target, path_source);
    } catch (error1) {
      error = error1;
      if (error.code !== 'EEXIST') {
        throw error;
      }
      info(`^77762-7^ symlink at ${path_source_rel} already exists, skipping`);
    }
    if (error == null) {
      help(`^77762-8^ created symlink ${rpr(path_source_rel)} -> ${path_target}`);
    }
    return null;
  };

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      var path_to_python, path_to_symlink;
      whisper("^77762-9^ running postinstall script for intershop-intertext");
      path_to_symlink = get_symlink_path();
      path_to_python = get_path_to_python_site_packages();
      return create_symlink(path_to_symlink, path_to_python);
    })();
  }

}).call(this);

//# sourceMappingURL=_postinstall.js.map