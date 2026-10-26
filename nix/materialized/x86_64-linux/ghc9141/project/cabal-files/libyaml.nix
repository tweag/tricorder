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
    flags = { no-unicode = false; system-libyaml = false; };
    package = {
      specVersion = "1.12";
      identifier = { name = "libyaml"; version = "0.1.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Michael Snoyman <michael@snoyman.com>";
      author = "Michael Snoyman <michael@snoyman.com>, Anton Ageev <antage@gmail.com>,Kirill Simonov";
      homepage = "https://github.com/snoyberg/yaml#readme";
      url = "";
      synopsis = "Low-level, streaming YAML interface.";
      description = "README and API documentation are available at <https://www.stackage.org/package/libyaml>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
        ] ++ pkgs.lib.optional (!flags.system-libyaml) (hsPkgs."libyaml-clib" or (errorHandler.buildDepError "libyaml-clib"))) ++ pkgs.lib.optional (system.isWindows) (hsPkgs."directory" or (errorHandler.buildDepError "directory"));
        pkgconfig = pkgs.lib.optional (!!flags.system-libyaml) (pkgconfPkgs."yaml-0.1" or (errorHandler.pkgConfDepError "yaml-0.1"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/libyaml-0.1.4.tar.gz";
      sha256 = "d6297ec9b1ebb4e4b580a4357d840d08a6f53e13a10c0c53ee74b973bba6fa13";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.36.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:           libyaml\nversion:        0.1.4\nsynopsis:       Low-level, streaming YAML interface.\ndescription:    README and API documentation are available at <https://www.stackage.org/package/libyaml>\ncategory:       Text\nstability:      stable\nhomepage:       https://github.com/snoyberg/yaml#readme\nbug-reports:    https://github.com/snoyberg/yaml/issues\nauthor:         Michael Snoyman <michael@snoyman.com>, Anton Ageev <antage@gmail.com>,Kirill Simonov\nmaintainer:     Michael Snoyman <michael@snoyman.com>\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    include/helper.h\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/snoyberg/yaml\n\nflag no-unicode\n  description: Don't enable unicode output. Instead, unicode characters will be escaped.\n  manual: False\n  default: False\n\nflag system-libyaml\n  description: Use the system-wide libyaml instead of the bundled copy\n  manual: False\n  default: False\n\nlibrary\n  exposed-modules:\n      Text.Libyaml\n  other-modules:\n      Paths_libyaml\n  hs-source-dirs:\n      src\n  ghc-options: -Wall\n  include-dirs:\n      include\n  c-sources:\n      c/helper.c\n  build-depends:\n      base >=4.14 && <5\n    , bytestring >=0.9.1.4\n    , conduit >=1.2.8 && <1.4\n    , resourcet >=0.3 && <1.4\n  default-language: Haskell2010\n  if flag(no-unicode)\n    cpp-options: -D__NO_UNICODE__\n  if !(flag(system-libyaml))\n    build-depends:\n        libyaml-clib\n  else\n    pkgconfig-depends:\n        yaml-0.1\n  if os(windows)\n    cpp-options: -DWINDOWS\n    build-depends:\n        directory\n";
  }