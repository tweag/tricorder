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
    flags = { cabal-syntax = false; };
    package = {
      specVersion = "1.18";
      identifier = { name = "hackage-security"; version = "0.6.4.0"; };
      license = "BSD-3-Clause";
      copyright = "Copyright 2015-2022 Well-Typed LLP";
      maintainer = "cabal-devel@haskell.org";
      author = "Edsko de Vries";
      homepage = "https://github.com/haskell/hackage-security";
      url = "";
      synopsis = "Hackage security library";
      description = "The hackage security library provides both server and\nclient utilities for securing the Hackage package server\n(<https://hackage.haskell.org/>).  It is based on The Update\nFramework (<https://theupdateframework.com/>), a set of\nrecommendations developed by security researchers at\nvarious universities in the US as well as developers on the\nTor project (<https://www.torproject.org/>).\n\nThe current implementation supports only index signing,\nthereby enabling untrusted mirrors. It does not yet provide\nfacilities for author package signing.\n\nThe library has two main entry points:\n\"Hackage.Security.Client\" is the main entry point for\nclients (the typical example being @cabal@), and\n\"Hackage.Security.Server\" is the main entry point for\nservers (the typical example being @hackage-server@).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."cryptohash-sha256" or (errorHandler.buildDepError "cryptohash-sha256"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."ed25519" or (errorHandler.buildDepError "ed25519"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."parsec" or (errorHandler.buildDepError "parsec"))
          (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
          (hsPkgs."tar" or (errorHandler.buildDepError "tar"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
        ] ++ (if flags.cabal-syntax
          then [
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
          ]
          else [
            (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
          ]);
        buildable = true;
      };
      tests = {
        "TestSuite" = {
          depends = [
            (hsPkgs."hackage-security" or (errorHandler.buildDepError "hackage-security"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
            (hsPkgs."tar" or (errorHandler.buildDepError "tar"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
          ] ++ [
            (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hackage-security-0.6.4.0.tar.gz";
      sha256 = "05e182e1a0968138dede99e4e96ed3c47ca0056efab0118ce34288e1531293d1";
    });
  }) // {
    package-description-override = "cabal-version:       1.18\nname:                hackage-security\nversion:             0.6.4.0\n\nsynopsis:            Hackage security library\ndescription:         The hackage security library provides both server and\n                     client utilities for securing the Hackage package server\n                     (<https://hackage.haskell.org/>).  It is based on The Update\n                     Framework (<https://theupdateframework.com/>), a set of\n                     recommendations developed by security researchers at\n                     various universities in the US as well as developers on the\n                     Tor project (<https://www.torproject.org/>).\n                     .\n                     The current implementation supports only index signing,\n                     thereby enabling untrusted mirrors. It does not yet provide\n                     facilities for author package signing.\n                     .\n                     The library has two main entry points:\n                     \"Hackage.Security.Client\" is the main entry point for\n                     clients (the typical example being @cabal@), and\n                     \"Hackage.Security.Server\" is the main entry point for\n                     servers (the typical example being @hackage-server@).\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Edsko de Vries\nmaintainer:          cabal-devel@haskell.org\ncopyright:           Copyright 2015-2022 Well-Typed LLP\ncategory:            Distribution\nhomepage:            https://github.com/haskell/hackage-security\nbug-reports:         https://github.com/haskell/hackage-security/issues\nbuild-type:          Simple\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.4\n  GHC == 9.10.3\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n\nextra-doc-files:\n  ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/haskell/hackage-security.git\n\nflag Cabal-syntax\n  description: Are we using Cabal-syntax?\n  manual: False\n  default: False\n\nlibrary\n  -- Most functionality is exported through the top-level entry points .Client\n  -- and .Server; the other exported modules are intended for qualified imports.\n  exposed-modules:     Hackage.Security.Client\n                       Hackage.Security.Client.Formats\n                       Hackage.Security.Client.Repository\n                       Hackage.Security.Client.Repository.Cache\n                       Hackage.Security.Client.Repository.Local\n                       Hackage.Security.Client.Repository.Remote\n                       Hackage.Security.Client.Repository.HttpLib\n                       Hackage.Security.Client.Verify\n                       Hackage.Security.JSON\n                       Hackage.Security.Key.Env\n                       Hackage.Security.Server\n                       Hackage.Security.Trusted\n                       Hackage.Security.TUF.FileMap\n                       Hackage.Security.Util.Checked\n                       Hackage.Security.Util.Path\n                       Hackage.Security.Util.Pretty\n                       Hackage.Security.Util.Some\n                       Text.JSON.Canonical\n  other-modules:       Hackage.Security.Key\n                       Hackage.Security.Trusted.TCB\n                       Hackage.Security.TUF\n                       Hackage.Security.TUF.Common\n                       Hackage.Security.TUF.FileInfo\n                       Hackage.Security.TUF.Header\n                       Hackage.Security.TUF.Layout.Cache\n                       Hackage.Security.TUF.Layout.Index\n                       Hackage.Security.TUF.Layout.Repo\n                       Hackage.Security.TUF.Mirrors\n                       Hackage.Security.TUF.Paths\n                       Hackage.Security.TUF.Patterns\n                       Hackage.Security.TUF.Root\n                       Hackage.Security.TUF.Signed\n                       Hackage.Security.TUF.Snapshot\n                       Hackage.Security.TUF.Targets\n                       Hackage.Security.TUF.Timestamp\n                       Hackage.Security.Util.Base64\n                       Hackage.Security.Util.Exit\n                       Hackage.Security.Util.IO\n                       Hackage.Security.Util.JSON\n                       Hackage.Security.Util.Lens\n                       Hackage.Security.Util.Stack\n                       Hackage.Security.Util.TypedEmbedded\n\n  build-depends:       base              >= 4.11     && < 4.23,\n                       base16-bytestring >= 0.1.1    && < 1.1,\n                       base64-bytestring >= 1.0      && < 1.3,\n                       bytestring        >= 0.10.8.2 && < 0.13,\n                       containers        >= 0.5.11   && < 0.9,\n                       cryptohash-sha256 >= 0.11     && < 0.12,\n                       directory         >= 1.3.1.5  && < 1.4,\n                       ed25519           >= 0.0      && < 0.1,\n                       filepath          >= 1.4.2    && < 1.6,\n                       mtl               >= 2.2.2    && < 2.4,\n                       network-uri       >= 2.6      && < 2.7,\n                       network           >= 2.6      && < 3.3,\n                       parsec            >= 3.1.13   && < 3.2,\n                       pretty            >= 1.0      && < 1.2,\n                       -- 0.4.2 introduces TarIndex, 0.4.4 introduces more\n                       -- functionality, 0.5.0 changes type of serialise\n                       tar               >= 0.5      && < 0.8,\n                       template-haskell  >= 2.13     && < 2.25,\n                       time              >= 1.8.0.2  && < 1.16,\n                       transformers      >= 0.3      && < 0.7,\n                       zlib              >= 0.5      && < 0.8,\n                       -- whatever versions are bundled with ghc:\n                       ghc-prim          >= 0.5.2    && < 0.14\n\n  if flag(Cabal-syntax)\n    build-depends: Cabal-syntax >= 3.7 && < 3.20\n  else\n    build-depends: Cabal        >= 2.2.0.1 && < 2.6\n                             || >= 3.0     && < 3.7,\n                   Cabal-syntax <  3.7\n\n  hs-source-dirs:      src\n  default-language:    Haskell2010\n  default-extensions:  DefaultSignatures\n                       DeriveDataTypeable\n                       DeriveFunctor\n                       FlexibleContexts\n                       FlexibleInstances\n                       GADTs\n                       GeneralizedNewtypeDeriving\n                       KindSignatures\n                       MultiParamTypeClasses\n                       NamedFieldPuns\n                       NoImplicitPrelude\n                       NoMonomorphismRestriction\n                       PatternSynonyms\n                       RankNTypes\n                       RecordWildCards\n                       ScopedTypeVariables\n                       StandaloneDeriving\n                       TupleSections\n                       TypeFamilies\n                       TypeOperators\n                       ViewPatterns\n  other-extensions:\n                       AllowAmbiguousTypes\n                       BangPatterns\n                       CPP\n                       DeriveLift\n                       OverlappingInstances\n                       PackageImports\n                       RoleAnnotations\n                       StaticPointers\n                       UndecidableInstances\n\n  ghc-options:         -Wall\n\ntest-suite TestSuite\n  type:                exitcode-stdio-1.0\n  main-is:             TestSuite.hs\n  other-modules:       TestSuite.HttpMem\n                       TestSuite.InMemCache\n                       TestSuite.InMemRepo\n                       TestSuite.InMemRepository\n                       TestSuite.JSON\n                       TestSuite.PrivateKeys\n                       TestSuite.Util.StrictMVar\n\n  -- inherited constraints from lib:hackage-security component\n  build-depends:       hackage-security,\n                       base,\n                       containers,\n                       bytestring,\n                       network-uri,\n                       tar,\n                       text,\n                       time,\n                       zlib\n\n  if flag(Cabal-syntax)\n    build-depends: Cabal        >= 3.7 && < 3.20,\n                   Cabal-syntax >= 3.7 && < 3.20\n  else\n    build-depends: Cabal        >= 2.2.0.1 && < 2.6\n                             || >= 3.0     && < 3.7,\n                   Cabal-syntax <  3.7\n\n  -- dependencies exclusive to test-suite\n  build-depends:       tasty                 >= 1.1.0.4  && < 1.6,\n                         -- tasty-1.1.0.4 is the version in Stackage LTS 12.26 (GHC 8.4)\n                       tasty-hunit           == 0.10.*,\n                       tasty-quickcheck      >= 0.10     && < 1,\n                       QuickCheck            >= 2.11     && < 2.19,\n                       aeson                 >= 1.4      && < 1.6 || >= 2.0 && < 2.4,\n                       vector                >= 0.12     && < 0.14,\n                       unordered-containers  >= 0.2.8.0  && < 0.3,\n                       temporary             >= 1.2      && < 1.4\n\n  hs-source-dirs:      tests\n  default-language:    Haskell2010\n  default-extensions:  FlexibleContexts\n                       GADTs\n                       KindSignatures\n                       RankNTypes\n                       RecordWildCards\n                       ScopedTypeVariables\n  ghc-options:         -Wall\n";
  }