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
    flags = { demos = false; };
    package = {
      specVersion = "3.0";
      identifier = { name = "vty-crossplatform"; version = "0.5.0.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2023 Jonathan Daugherty";
      maintainer = "cygnus@foobox.com";
      author = "Jonathan Daugherty";
      homepage = "";
      url = "";
      synopsis = "Cross-platform support for Vty";
      description = "This package provides a generic interface for multiple\nVty platforms in one package so you don't have to\nconditionally depend on them in your cabal file.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
        ] ++ (if system.isOsx
          then [
            (hsPkgs."vty-unix" or (errorHandler.buildDepError "vty-unix"))
          ]
          else if system.isLinux
            then [
              (hsPkgs."vty-unix" or (errorHandler.buildDepError "vty-unix"))
            ]
            else if system.isFreebsd || system.isOpenbsd || system.isNetbsd || system.isDragonFly
              then [
                (hsPkgs."vty-unix" or (errorHandler.buildDepError "vty-unix"))
              ]
              else if system.isSolaris || system.isAix || system.isHPUX || system.isIRIX || system.isHurd
                then [
                  (hsPkgs."vty-unix" or (errorHandler.buildDepError "vty-unix"))
                ]
                else pkgs.lib.optional (system.isWindows) (hsPkgs."vty-windows" or (errorHandler.buildDepError "vty-windows")));
        buildable = if system.isOsx
          then true
          else if system.isLinux
            then true
            else if system.isFreebsd || system.isOpenbsd || system.isNetbsd || system.isDragonFly
              then true
              else if system.isSolaris || system.isAix || system.isHPUX || system.isIRIX || system.isHurd
                then true
                else if system.isWindows then true else false;
      };
      exes = {
        "vty-rogue-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "vty-event-echo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "vty-mode-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "vty-interactive-terminal-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."string-qq" or (errorHandler.buildDepError "string-qq"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
          ];
          buildable = if !flags.demos then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/vty-crossplatform-0.5.0.0.tar.gz";
      sha256 = "3a936f1c69802f718039e2da57347ade52fc12cd4ac995fcef7c4e6f745f3336";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\nname:               vty-crossplatform\nversion:            0.5.0.0\nsynopsis:           Cross-platform support for Vty\ndescription:        This package provides a generic interface for multiple\n                    Vty platforms in one package so you don't have to\n                    conditionally depend on them in your cabal file.\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Jonathan Daugherty\nmaintainer:         cygnus@foobox.com\ncopyright:          (c) 2023 Jonathan Daugherty\ncategory:           Graphics\nbuild-type:         Simple\nextra-doc-files:    CHANGELOG.md\n\ncommon warnings\n    ghc-options: -Wall\n\nFlag demos\n    Description:     Build demonstration programs\n    Default:         False\n\nlibrary\n    import:           warnings\n    hs-source-dirs:   src\n    default-language: Haskell2010\n    exposed-modules:  Graphics.Vty.CrossPlatform\n                    , Graphics.Vty.CrossPlatform.Testing\n    build-depends:    base >= 4.8 && < 5,\n                      vty >= 6.1\n\n    if os(darwin)\n        build-depends:  vty-unix\n    elif os(linux)\n        build-depends:  vty-unix\n    elif os(freebsd) || os(openbsd) || os(netbsd) || os(dragonfly)\n        build-depends:  vty-unix\n    elif os(solaris) || os(aix) || os(hpux) || os(irix) || os(hurd)\n        build-depends:  vty-unix\n    elif os(windows)\n        build-depends:  vty-windows >= 0.2.0.1\n    else\n        Buildable: False\n\nexecutable vty-rogue-demo\n    if !flag(demos)\n        Buildable: False\n\n    hs-source-dirs:      programs\n    ghc-options:         -threaded -Wall -Wcompat -O2\n    default-language:    Haskell2010\n    default-extensions:  CPP\n    main-is:             Rogue.hs\n    build-depends:       base,\n                         vty,\n                         vty-crossplatform,\n                         random,\n                         mtl,\n                         array\n\nexecutable vty-event-echo\n    if !flag(demos)\n        Buildable: False\n\n    hs-source-dirs:      programs\n    ghc-options:         -threaded -Wall -Wcompat -O2\n    default-language:    Haskell2010\n    default-extensions:  CPP\n    main-is:             EventEcho.hs\n    build-depends:       base,\n                         vty,\n                         vty-crossplatform,\n                         containers,\n                         mtl\n\nexecutable vty-mode-demo\n    if !flag(demos)\n        Buildable: False\n\n    hs-source-dirs:      programs\n    ghc-options:         -threaded -Wall -Wcompat -O2\n    default-language:    Haskell2010\n    default-extensions:  CPP\n    main-is:             ModeDemo.hs\n    build-depends:       base,\n                         vty,\n                         vty-crossplatform\n\nexecutable vty-interactive-terminal-test\n    if !flag(demos)\n        Buildable: False\n\n    hs-source-dirs:      programs\n    ghc-options:         -threaded -Wall -Wcompat -O2\n    default-language:    Haskell2010\n    default-extensions:  CPP\n    main-is:             interactive_terminal_test.hs\n    build-depends:       base,\n                         string-qq,\n                         vty,\n                         vty-crossplatform\n";
  }