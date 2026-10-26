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
      specVersion = "1.10";
      identifier = { name = "fast-logger"; version = "3.2.8"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Kazu Yamamoto <kazu@iij.ad.jp>";
      homepage = "https://github.com/kazu-yamamoto/logger";
      url = "";
      synopsis = "A fast logging system";
      description = "A fast logging system for Haskell";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
          (hsPkgs."easy-file" or (errorHandler.buildDepError "easy-file"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."unix-time" or (errorHandler.buildDepError "unix-time"))
          (hsPkgs."unix-compat" or (errorHandler.buildDepError "unix-compat"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "7.8") (hsPkgs."bytestring-builder" or (errorHandler.buildDepError "bytestring-builder"));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."fast-logger" or (errorHandler.buildDepError "fast-logger"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/fast-logger-3.2.8.tar.gz";
      sha256 = "39cdaf2c12b2f795be30d85eb638785f74aa5162c6daf827b5ca202511debc8f";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               fast-logger\nversion:            3.2.8\nlicense:            BSD3\nlicense-file:       LICENSE\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:             Kazu Yamamoto <kazu@iij.ad.jp>\ntested-with:\n    ghc ==7.8.4 || ==7.10.3 || ==8.0.2 || ==8.2.2 || ==8.4.4 || ==8.6.3\n\nhomepage:           https://github.com/kazu-yamamoto/logger\nsynopsis:           A fast logging system\ndescription:        A fast logging system for Haskell\ncategory:           System\nbuild-type:         Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/logger.git\n\nlibrary\n    exposed-modules:\n        System.Log.FastLogger\n        System.Log.FastLogger.Date\n        System.Log.FastLogger.File\n        System.Log.FastLogger.Internal\n        System.Log.FastLogger.LoggerSet\n        System.Log.FastLogger.Types\n\n    other-modules:\n        System.Log.FastLogger.Imports\n        System.Log.FastLogger.FileIO\n        System.Log.FastLogger.IO\n        System.Log.FastLogger.LogStr\n        System.Log.FastLogger.MultiLogger\n        System.Log.FastLogger.SingleLogger\n        System.Log.FastLogger.Write\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4.9 && <5,\n        array,\n        auto-update >=0.2.2,\n        easy-file >=0.2,\n        bytestring >=0.10.4,\n        directory,\n        filepath,\n        stm,\n        text,\n        unix-time >=0.4.4,\n        unix-compat >=0.2\n\n    if impl(ghc <7.8)\n        build-depends: bytestring-builder\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n\ntest-suite spec\n    type:             exitcode-stdio-1.0\n    main-is:          Spec.hs\n    build-tools:      hspec-discover >=2.6\n    hs-source-dirs:   test\n    other-modules:    FastLoggerSpec\n    default-language: Haskell2010\n    ghc-options:      -Wall -threaded -rtsopts -with-rtsopts=-N\n    build-depends:\n        base >=4 && <5,\n        async,\n        bytestring >=0.10.4,\n        directory,\n        fast-logger,\n        hspec\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n";
  }