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
      specVersion = "1.18";
      identifier = { name = "old-time"; version = "1.1.1.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "https://github.com/haskell/old-time";
      author = "";
      homepage = "";
      url = "";
      synopsis = "Time library";
      description = "This is a legacy package, please migrate away to\n<http://hackage.haskell.org/package/time time> or elsewhere.";
      buildType = "Configure";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."old-locale" or (errorHandler.buildDepError "old-locale"))
        ];
        build-tools = [
          (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")))
        ];
        buildable = true;
      };
      tests = {
        "old-time-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."old-locale" or (errorHandler.buildDepError "old-locale"))
            (hsPkgs."old-time" or (errorHandler.buildDepError "old-time"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/old-time-1.1.1.0.tar.gz";
      sha256 = "2c440d3bc2680defcb379a4b5e6469c5dff1d3400374aac60523cef78c3d96ab";
    });
  }) // {
    package-description-override = "cabal-version:  1.18\nname:           old-time\nversion:        1.1.1.0\nlicense:        BSD3\nlicense-file:   LICENSE\nmaintainer:     https://github.com/haskell/old-time\nbug-reports:    https://github.com/haskell/old-time/issues\nsynopsis:       Time library\ncategory:       System\nbuild-type:     Configure\ndescription:\n    This is a legacy package, please migrate away to\n    <http://hackage.haskell.org/package/time time> or elsewhere.\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.3\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nextra-doc-files:\n    changelog.md\n\nextra-source-files:\n    aclocal.m4\n    config.guess\n    config.sub\n    configure\n    configure.ac\n    include/HsTimeConfig.h.in\n    install-sh\n    old-time.buildinfo\n\nextra-tmp-files:\n    autom4te.cache\n    config.log\n    config.status\n    include/HsTimeConfig.h\n\nsource-repository head\n    type:     git\n    location: https://github.com/haskell/old-time.git\n\nLibrary\n    default-language: Haskell2010\n    other-extensions: Trustworthy CApiFFI\n\n    exposed-modules:\n        System.Time\n\n    c-sources:\n        cbits/timeUtils.c\n\n    include-dirs: include\n    install-includes:\n        HsTime.h\n\n    build-depends:\n        base       >= 4.8 && < 5,\n        old-locale == 1.0.*\n\n    build-tools: hsc2hs\n\n    ghc-options: -Wall\n\ntest-suite old-time-tests\n    type: exitcode-stdio-1.0\n    default-language: Haskell2010\n    ghc-options: -Wall\n    main-is: Tests.hs\n    hs-source-dirs: tests\n    build-depends:\n        base,\n        old-locale < 2,\n        old-time,\n        tasty < 2,\n        tasty-hunit < 1\n";
  }