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
      identifier = { name = "ghcid"; version = "1.0.0"; };
      license = "BSD-3-Clause";
      copyright = "Neil Mitchell 2014-2026";
      maintainer = "Neil Mitchell <ndmitchell@gmail.com>";
      author = "Neil Mitchell <ndmitchell@gmail.com>, jpmoresmau";
      homepage = "https://github.com/ndmitchell/ghcid#readme";
      url = "";
      synopsis = "GHCi based bare bones IDE";
      description = "Either \\\"GHCi as a daemon\\\" or \\\"GHC + a bit of an IDE\\\". A very simple Haskell development tool which shows you the errors in your project and updates them whenever you save. Run @ghcid --topmost --command=ghci@, where @--topmost@ makes the window on top of all others (Windows only) and @--command@ is the command to start GHCi on your project (defaults to @ghci@ if you have a @.ghci@ file, or else to @cabal repl@).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."cmdargs" or (errorHandler.buildDepError "cmdargs"))
        ] ++ pkgs.lib.optional (!system.isWindows) (hsPkgs."unix" or (errorHandler.buildDepError "unix"));
        buildable = true;
      };
      exes = {
        "ghcid" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."fsnotify" or (errorHandler.buildDepError "fsnotify"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."cmdargs" or (errorHandler.buildDepError "cmdargs"))
            (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
            (hsPkgs."terminal-size" or (errorHandler.buildDepError "terminal-size"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."cryptohash-sha256" or (errorHandler.buildDepError "cryptohash-sha256"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."microaeson" or (errorHandler.buildDepError "microaeson"))
          ] ++ (if system.isWindows
            then [ (hsPkgs."Win32" or (errorHandler.buildDepError "Win32")) ]
            else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
          buildable = true;
        };
      };
      tests = {
        "ghcid_test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."fsnotify" or (errorHandler.buildDepError "fsnotify"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
            (hsPkgs."terminal-size" or (errorHandler.buildDepError "terminal-size"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."cryptohash-sha256" or (errorHandler.buildDepError "cryptohash-sha256"))
            (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."microaeson" or (errorHandler.buildDepError "microaeson"))
            (hsPkgs."cmdargs" or (errorHandler.buildDepError "cmdargs"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ] ++ (if system.isWindows
            then [ (hsPkgs."Win32" or (errorHandler.buildDepError "Win32")) ]
            else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/ghcid-1.0.0.tar.gz";
      sha256 = "66bf8d461f48e16e2c53a6d7c491886a423a190ce7bcae8fcc20a3d8c3121dee";
    });
  }) // {
    package-description-override = "cabal-version:      1.18\nbuild-type:         Simple\nname:               ghcid\nversion:            1.0.0\nlicense:            BSD3\nlicense-file:       LICENSE\ncategory:           Development\nauthor:             Neil Mitchell <ndmitchell@gmail.com>, jpmoresmau\nmaintainer:         Neil Mitchell <ndmitchell@gmail.com>\ncopyright:          Neil Mitchell 2014-2026\nsynopsis:           GHCi based bare bones IDE\ndescription:\n    Either \\\"GHCi as a daemon\\\" or \\\"GHC + a bit of an IDE\\\". A very simple Haskell development tool which shows you the errors in your project and updates them whenever you save. Run @ghcid --topmost --command=ghci@, where @--topmost@ makes the window on top of all others (Windows only) and @--command@ is the command to start GHCi on your project (defaults to @ghci@ if you have a @.ghci@ file, or else to @cabal repl@).\nhomepage:           https://github.com/ndmitchell/ghcid#readme\nbug-reports:        https://github.com/ndmitchell/ghcid/issues\ntested-with:        GHC==9.12, GHC==9.10, GHC==9.8, GHC==9.6, GHC==9.4, GHC==9.2, GHC==9.0, GHC==8.10, GHC==8.8\nextra-doc-files:\n    CHANGES.txt\n    README.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/ndmitchell/ghcid.git\n\nlibrary\n    hs-source-dirs:  src\n    default-language: Haskell2010\n    build-depends:\n        base >= 4.7 && < 5,\n        filepath,\n        time >= 1.5,\n        directory >= 1.2,\n        extra >= 1.6.20,\n        process >= 1.1,\n        ansi-terminal,\n        cmdargs >= 0.10\n    if !os(windows)\n        build-depends:\n            unix\n\n    exposed-modules:\n        Language.Haskell.Ghcid\n    other-modules:\n        Paths_ghcid\n        Language.Haskell.Ghcid.Escape\n        Language.Haskell.Ghcid.Parser\n        Language.Haskell.Ghcid.Types\n        Language.Haskell.Ghcid.Util\n\nexecutable ghcid\n    hs-source-dirs: app, src\n    default-language: Haskell2010\n    ghc-options: -main-is Ghcid.main -threaded -rtsopts\n    main-is: Ghcid.hs\n    build-depends:\n        base >= 4.7 && < 5,\n        filepath,\n        time >= 1.5,\n        directory >= 1.2,\n        containers,\n        fsnotify >= 0.4,\n        extra >= 1.6.20,\n        async,\n        process >= 1.1,\n        cmdargs >= 0.10,\n        ansi-terminal,\n        terminal-size >= 0.3,\n        temporary,\n        network,\n        cryptohash-sha256,\n        bytestring,\n        base64-bytestring,\n        text,\n        microaeson\n    if os(windows)\n        build-depends: Win32 >= 2.13.2.1\n    else\n        build-depends: unix\n    other-modules:\n        Language.Haskell.Ghcid.Escape\n        Language.Haskell.Ghcid.Parser\n        Language.Haskell.Ghcid.Terminal\n        Language.Haskell.Ghcid.Types\n        Language.Haskell.Ghcid.Util\n        Language.Haskell.Ghcid\n        Paths_ghcid\n        Server\n        Session\n        Wait\n\ntest-suite ghcid_test\n    type:            exitcode-stdio-1.0\n    hs-source-dirs:  test, app, src\n    main-is:         Test.hs\n    ghc-options:     -rtsopts -main-is Test.main -threaded -with-rtsopts=-K1K\n    default-language: Haskell2010\n    build-depends:\n        base >= 4.7 && < 5,\n        filepath,\n        time >= 1.5,\n        directory >= 1.2,\n        process,\n        containers,\n        fsnotify >= 0.4,\n        extra >= 1.6.6,\n        async,\n        ansi-terminal,\n        terminal-size >= 0.3,\n        temporary,\n        bytestring,\n        network,\n        cryptohash-sha256,\n        base64-bytestring,\n        text,\n        microaeson,\n        cmdargs,\n        tasty,\n        tasty-hunit\n    if os(windows)\n        build-depends: Win32\n    else\n        build-depends: unix\n    other-modules:\n        Ghcid\n        Language.Haskell.Ghcid\n        Language.Haskell.Ghcid.Escape\n        Language.Haskell.Ghcid.Parser\n        Language.Haskell.Ghcid.Terminal\n        Language.Haskell.Ghcid.Types\n        Language.Haskell.Ghcid.Util\n        Paths_ghcid\n        Server\n        Session\n        Test.API\n        Test.Common\n        Test.Ghcid\n        Test.Parser\n        Test.Util\n        Wait\n";
  }