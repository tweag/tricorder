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
    flags = { allow-bsd = true; fallback = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "simple-sendfile"; version = "0.2.32"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Kazu Yamamoto <kazu@iij.ad.jp>";
      homepage = "";
      url = "";
      synopsis = "Cross platform library for the sendfile system call";
      description = "Cross platform library for the sendfile system call.\nThis library tries to call minimum system calls which\nare the bottleneck of web servers.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ] ++ (if system.isFreebsd && flags.allow-bsd && !flags.fallback
          then [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]
          else if system.isOsx && !flags.fallback
            then [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]
            else if system.isLinux && !flags.fallback
              then [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]
              else [
                (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
                (hsPkgs."conduit-extra" or (errorHandler.buildDepError "conduit-extra"))
                (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
                (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
              ]);
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
            (hsPkgs."conduit-extra" or (errorHandler.buildDepError "conduit-extra"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."easy-file" or (errorHandler.buildDepError "easy-file"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
            (hsPkgs."simple-sendfile" or (errorHandler.buildDepError "simple-sendfile"))
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
      url = "http://hackage.haskell.org/package/simple-sendfile-0.2.32.tar.gz";
      sha256 = "9f28d0a67ac3d956d2dd78eb19ea922c0a9192bbbeeeead20d39f561636828a3";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               simple-sendfile\nversion:            0.2.32\nlicense:            BSD3\nlicense-file:       LICENSE\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:             Kazu Yamamoto <kazu@iij.ad.jp>\nsynopsis:           Cross platform library for the sendfile system call\ndescription:\n    Cross platform library for the sendfile system call.\n    This library tries to call minimum system calls which\n    are the bottleneck of web servers.\n\ncategory:           Network\nbuild-type:         Simple\nextra-source-files: test/inputFile\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/simple-sendfile\n\nflag allow-bsd\n    description: Allow use of BSD sendfile (disable on GNU/kFreeBSD)\n\nflag fallback\n    description: Use conduit instead of sendfile()\n    default: False\n\nlibrary\n    exposed-modules:  Network.Sendfile\n    other-modules:    Network.Sendfile.Types\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4.8 && <5,\n        network >=3.1.4,\n        bytestring\n\n    if (os(freebsd) && flag(allow-bsd) && !flag(fallback))\n        cpp-options:   -DOS_BSD\n        other-modules:\n            Network.Sendfile.BSD\n            Network.Sendfile.IOVec\n\n        build-depends: unix\n\n    else\n        if (os(osx) && !flag(fallback))\n            cpp-options:   -DOS_MacOS\n            other-modules:\n                Network.Sendfile.BSD\n                Network.Sendfile.IOVec\n\n            build-depends: unix\n\n        else\n            if (os(linux) && !flag(fallback))\n                exposed-modules: System.Linux.Sendfile\n                cpp-options:     -DOS_Linux\n                other-modules:   Network.Sendfile.Linux\n                build-depends:   unix\n\n            else\n                other-modules: Network.Sendfile.Fallback\n                build-depends:\n                    conduit >=1.0 && <1.4,\n                    conduit-extra >=1.0 && <1.4,\n                    transformers >=0.2.2 && <0.7,\n                    resourcet\n\ntest-suite spec\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test\n    other-modules:      SendfileSpec\n    default-language:   Haskell2010\n    ghc-options:        -Wall\n    build-depends:\n        HUnit,\n        base,\n        bytestring,\n        conduit,\n        conduit-extra,\n        directory,\n        easy-file >= 0.2.4,\n        hspec >=1.3,\n        network,\n        process,\n        resourcet,\n        simple-sendfile\n";
  }