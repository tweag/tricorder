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
      specVersion = "1.24";
      identifier = { name = "daemons"; version = "0.4.0"; };
      license = "GPL-3.0-only";
      copyright = "";
      maintainer = "scvalex@gmail.com";
      author = "Alexandru Scvortov <scvalex@gmail.com>";
      homepage = "https://github.com/scvalex/daemons";
      url = "";
      synopsis = "Daemons in Haskell made fun and easy";
      description = "\"Control.Pipe.C3\" provides simple RPC-like wrappers for pipes.\n\n\"Control.Pipe.Serialize\" provides serialization and\nincremental deserialization pipes.\n\n\"Control.Pipe.Socket\" provides functions to setup pipes around\nsockets.\n\n\"System.Daemon\" provides a high-level interface to starting\ndaemonized programs that are controlled through sockets.\n\n\"System.Posix.Daemon\" provides a low-level interface to\nstarting, and controlling detached jobs.\n\nSee the @README.md@ file and the homepage for details.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."pipes" or (errorHandler.buildDepError "pipes"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
        ];
        buildable = true;
      };
      exes = {
        "memo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."daemons" or (errorHandler.buildDepError "daemons"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          ];
          buildable = true;
        };
        "addone" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."daemons" or (errorHandler.buildDepError "daemons"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          ];
          buildable = true;
        };
        "queue" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."daemons" or (errorHandler.buildDepError "daemons"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."pipes" or (errorHandler.buildDepError "pipes"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = true;
        };
        "name" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."daemons" or (errorHandler.buildDepError "daemons"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          ];
          buildable = true;
        };
      };
      tests = {
        "daemon" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."daemons" or (errorHandler.buildDepError "daemons"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-hunit" or (errorHandler.buildDepError "test-framework-hunit"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/daemons-0.4.0.tar.gz";
      sha256 = "1f1a2497c9bacc290bfc7dc6ca54020b39570b3516dbf938ad20e144ceeccc81";
    });
  }) // {
    package-description-override = "Name:           daemons\nVersion:        0.4.0\nCabal-Version:  1.24\nLicense:        GPL-3\nLicense-File:   LICENSE\nStability:      experimental\nAuthor:         Alexandru Scvortov <scvalex@gmail.com>\nMaintainer:     scvalex@gmail.com\nHomepage:       https://github.com/scvalex/daemons\nCategory:       System, Control, Network\nSynopsis:       Daemons in Haskell made fun and easy\nBuild-Type:     Simple\nDescription:\n        \"Control.Pipe.C3\" provides simple RPC-like wrappers for pipes.\n        .\n        \"Control.Pipe.Serialize\" provides serialization and\n        incremental deserialization pipes.\n        .\n        \"Control.Pipe.Socket\" provides functions to setup pipes around\n        sockets.\n        .\n        \"System.Daemon\" provides a high-level interface to starting\n        daemonized programs that are controlled through sockets.\n        .\n        \"System.Posix.Daemon\" provides a low-level interface to\n        starting, and controlling detached jobs.\n        .\n        See the @README.md@ file and the homepage for details.\n\nExtra-Source-Files:     Makefile\n\nData-Files:             README.md, NEWS.md, LICENSE, examples/Memo.md\n\nSource-repository head\n  Type:                 git\n  Location:             git://github.com/scvalex/daemons.git\n\nLibrary\n  Hs-Source-Dirs:       src\n  Build-depends:        base >= 4.18 && < 5,\n                        bytestring,\n                        cereal >= 0.4.0,\n                        data-default,\n                        directory,\n                        filepath,\n                        ghc-prim,\n                        network,\n                        pipes >= 4.0.0,\n                        transformers,\n                        unix\n  Ghc-options:          -Wall\n  Exposed-modules:      Control.Pipe.C3,\n                        Control.Pipe.Serialize,\n                        Control.Pipe.Socket,\n                        System.Daemon,\n                        System.Posix.Daemon\n  Other-modules:\n  Default-language:     Haskell2010\n\nExecutable memo\n  Build-depends:        base >= 4.18 && < 5, bytestring, cereal, containers,\n                        daemons, data-default, ghc-prim\n  Main-Is:              examples/Memo.hs\n  Ghc-options:          -Wall\n  Default-language:     Haskell2010\n\nExecutable addone\n  Build-depends:        base >= 4.18 && < 5, daemons, data-default, ghc-prim\n  Main-Is:              examples/AddOne.hs\n  Ghc-options:          -Wall\n  Default-language:     Haskell2010\n\nExecutable queue\n  Build-depends:        base >= 4.18 && < 5, bytestring, cereal, containers,\n                        daemons, data-default, ghc-prim, network,\n                        pipes >= 4.0.0, transformers\n  Main-Is:              examples/Queue.hs\n  Ghc-options:          -Wall\n  Default-language:     Haskell2010\n\nExecutable name\n  Build-depends:        base >= 4.18 && < 5, bytestring, cereal, containers,\n                        daemons, data-default, ghc-prim\n  Main-Is:              examples/Name.hs\n  Ghc-options:          -Wall\n  Default-language:     Haskell2010\n\nTest-suite daemon\n  Hs-Source-Dirs:       test\n  Main-Is:              Daemon.hs\n  Type:                 exitcode-stdio-1.0\n  Build-Depends:        base >= 4.18 && < 5, daemons, data-default, directory,\n                        ghc-prim, HUnit, test-framework, test-framework-hunit,\n                        unix\n  Ghc-Options:          -Wall\n  Default-language:     Haskell2010\n";
  }