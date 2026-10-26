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
      identifier = { name = "ki"; version = "1.0.1.2"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2020-2025 Mitchell Dalvi Rosen, Travis Staton";
      maintainer = "Mitchell Dalvi Rosen <mitchellwrosen@gmail.com>, Travis Staton <hello@travisstaton.com>";
      author = "Mitchell Dalvi Rosen, Travis Staton";
      homepage = "https://github.com/awkward-squad/ki";
      url = "";
      synopsis = "A lightweight structured concurrency library";
      description = "A lightweight structured concurrency library.\n\nFor a variant of this API generalized to\n@<https://hackage.haskell.org/package/unliftio-core/docs/Control-Monad-IO-Unlift.html#t:MonadUnliftIO MonadUnliftIO>@,\nsee @<https://hackage.haskell.org/package/ki-unlifted ki-unlifted>@.\n\nRemember to link your program with @-threaded@ to use the threaded runtime!";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."int-supply" or (errorHandler.buildDepError "int-supply"))
        ];
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ki" or (errorHandler.buildDepError "ki"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/ki-1.0.1.2.tar.gz";
      sha256 = "73b23cb5044d50276003e1dda26f7c15ecb0b324ef4fd546b4f7ad3ccd54ec98";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\n\nauthor: Mitchell Dalvi Rosen, Travis Staton\nbug-reports: https://github.com/awkward-squad/ki/issues\ncategory: Concurrency\ncopyright: Copyright (C) 2020-2025 Mitchell Dalvi Rosen, Travis Staton\nhomepage: https://github.com/awkward-squad/ki\nlicense: BSD-3-Clause\nlicense-file: LICENSE\nmaintainer: Mitchell Dalvi Rosen <mitchellwrosen@gmail.com>, Travis Staton <hello@travisstaton.com>\nname: ki\nstability: stable\nsynopsis: A lightweight structured concurrency library\ntested-with: GHC == 9.8.4, GHC == 9.10.1, GHC == 9.12.1\nversion: 1.0.1.2\nx-revision: 3\n\ndescription:\n  A lightweight structured concurrency library.\n  .\n  For a variant of this API generalized to\n  @<https://hackage.haskell.org/package/unliftio-core/docs/Control-Monad-IO-Unlift.html#t:MonadUnliftIO MonadUnliftIO>@,\n  see @<https://hackage.haskell.org/package/ki-unlifted ki-unlifted>@.\n  .\n  Remember to link your program with @-threaded@ to use the threaded runtime!\n\nextra-doc-files:\n  CHANGELOG.md\n  README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/awkward-squad/ki.git\n  subdir: ki\n\ncommon component\n  build-depends:\n    base ^>= 4.12\n      || ^>= 4.13\n      || ^>= 4.14\n      || ^>= 4.15\n      || ^>= 4.16\n      || ^>= 4.17\n      || ^>= 4.18\n      || ^>= 4.19\n      || ^>= 4.20\n      || ^>= 4.21\n      || ^>= 4.22,\n  default-extensions:\n    AllowAmbiguousTypes\n    BangPatterns\n    BlockArguments\n    ConstraintKinds\n    DeriveAnyClass\n    DeriveDataTypeable\n    DeriveFunctor\n    DeriveGeneric\n    DerivingStrategies\n    DuplicateRecordFields\n    ExistentialQuantification\n    GeneralizedNewtypeDeriving\n    InstanceSigs\n    LambdaCase\n    NamedFieldPuns\n    NumericUnderscores\n    PartialTypeSignatures\n    PatternSynonyms\n    RankNTypes\n    RoleAnnotations\n    ScopedTypeVariables\n    TypeApplications\n    ViewPatterns\n  default-language: Haskell2010\n  ghc-options:\n    -Weverything\n    -Wno-all-missed-specialisations\n    -Wno-implicit-prelude\n    -Wno-missed-specialisations\n    -Wno-missing-import-lists\n    -Wno-safe\n    -Wno-unsafe\n  if impl(ghc >= 8.10)\n    ghc-options:\n      -Wno-missing-safe-haskell-mode\n      -Wno-prepositive-qualified-module\n  if impl(ghc >= 9.2)\n    ghc-options:\n      -Wno-missing-kind-signatures\n  if impl(ghc >= 9.8)\n    ghc-options:\n      -Wno-missing-role-annotations\n\nlibrary\n  import: component\n  build-depends:\n    containers ^>= 0.6 || ^>= 0.7 || ^>= 0.8,\n    int-supply ^>= 1.0.0,\n  exposed-modules:\n    Ki\n  hs-source-dirs: src\n  other-modules:\n    Ki.Internal.ByteCount\n    Ki.Internal.IO\n    Ki.Internal.NonblockingSTM\n    Ki.Internal.Propagating\n    Ki.Internal.Scope\n    Ki.Internal.Thread\n    Ki.Internal.ThreadAffinity\n    Ki.Internal.ThreadOptions\n\ntest-suite tests\n  import: component\n  build-depends:\n    ki,\n    stm ^>= 2.5,\n    tasty ^>= 1.4.2 || ^>= 1.5,\n    tasty-hunit ^>= 0.10,\n  ghc-options: -rtsopts -threaded\n  hs-source-dirs: test\n  main-is: Tests.hs\n  type: exitcode-stdio-1.0\n";
  }