{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  ({
    flags = {};
    package = {
      specVersion = "2.2";
      identifier = { name = "libyaml-clib"; version = "0.2.5"; };
      license = "MIT";
      copyright = "";
      maintainer = "Julian Ospald <hasufell@posteo.de>";
      author = "Julian Ospald <hasufell@posteo.de>";
      homepage = "https://github.com/hasufell/streamly-yaml#readme";
      url = "";
      synopsis = "libyaml clibs";
      description = "libyaml C source code for yaml bindings";
      buildType = "Simple";
    };
    components = { "library" = { buildable = true; }; };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/libyaml-clib-0.2.5.tar.gz";
      sha256 = "04526bc54e5fcf471c2bd22854e6b519e162a6e3d654e866cd8862103c725149";
    });
  }) // {
    package-description-override = "cabal-version:      2.2\nname:               libyaml-clib\nversion:            0.2.5\nsynopsis:           libyaml clibs\ndescription:        libyaml C source code for yaml bindings\ncategory:           Text\nstability:          stable\nhomepage:           https://github.com/hasufell/streamly-yaml#readme\nbug-reports:        https://github.com/hasufell/streamly-yaml\nauthor:             Julian Ospald <hasufell@posteo.de>\nmaintainer:         Julian Ospald <hasufell@posteo.de>\nlicense:            MIT\nlicense-file:       cbits/License\nbuild-type:         Simple\nextra-doc-files:    README.md\n                    CHANGELOG.md\n                    cbits/License\n\nsource-repository head\n  type:     git\n  location: https://github.com/hasufell/streamly-yaml\n\nlibrary\n  default-language: Haskell2010\n  include-dirs:     cbits\n  includes:         yaml.h\n  c-sources:\n    cbits/writer.c\n    cbits/dumper.c\n    cbits/loader.c\n    cbits/api.c\n    cbits/scanner.c\n    cbits/emitter.c\n    cbits/parser.c\n    cbits/reader.c\n\n  install-includes:\n    yaml.h\n    yaml_private.h\n";
  }