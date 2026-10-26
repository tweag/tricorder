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
      specVersion = "3.0";
      identifier = { name = "deferred-folds"; version = "0.9.18.10"; };
      license = "MIT";
      copyright = "(c) 2018, Metrix.AI";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/deferred-folds";
      url = "";
      synopsis = "Abstractions over deferred folds";
      description = "This library is in an experimental state.\nUsers should be prepared for frequent updates.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."foldl" or (errorHandler.buildDepError "foldl"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."deferred-folds" or (errorHandler.buildDepError "deferred-folds"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/deferred-folds-0.9.18.10.tar.gz";
      sha256 = "4b50077e7d59a1201485cc6f6d0f2cab11bb1e462f4fc5e17d9b5f210126e1a3";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: deferred-folds\nversion: 0.9.18.10\ncategory: Folding\nsynopsis: Abstractions over deferred folds\ndescription:\n  This library is in an experimental state.\n  Users should be prepared for frequent updates.\n\nstability: Experimental\nhomepage: https://github.com/nikita-volkov/deferred-folds\nbug-reports: https://github.com/nikita-volkov/deferred-folds/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2018, Metrix.AI\nlicense: MIT\nlicense-file: LICENSE\nbuild-type: Simple\n\nsource-repository head\n  type: git\n  location: https://github.com/nikita-volkov/deferred-folds\n\nlibrary\n  hs-source-dirs: library\n  default-extensions:\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    PatternSynonyms\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\n  default-language: Haskell2010\n  exposed-modules:\n    DeferredFolds.Unfoldl\n    DeferredFolds.UnfoldlM\n    DeferredFolds.Unfoldr\n\n  other-modules:\n    DeferredFolds.Defs.Unfoldl\n    DeferredFolds.Defs.UnfoldlM\n    DeferredFolds.Defs.Unfoldr\n    DeferredFolds.Defs.UnfoldrM\n    DeferredFolds.Prelude\n    DeferredFolds.Types\n    DeferredFolds.UnfoldrM\n    DeferredFolds.Util.TextArray\n\n  build-depends:\n    base >=4.9 && <5,\n    bytestring >=0.10 && <0.13,\n    containers >=0.5 && <0.9,\n    foldl >=1 && <2,\n    hashable >=1 && <2,\n    primitive >=0.6.4 && <0.10,\n    text >=1.2 && <1.3 || >=2.0 && <2.2,\n    transformers >=0.5 && <0.7,\n    unordered-containers >=0.2 && <0.3,\n    vector >=0.12 && <0.14,\n\ntest-suite test\n  type: exitcode-stdio-1.0\n  hs-source-dirs: test\n  default-extensions:\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    PatternSynonyms\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\n  default-language: Haskell2010\n  main-is: Main.hs\n  build-depends:\n    deferred-folds,\n    quickcheck-instances >=0.3.11 && <0.5,\n    rerebase <2,\n    tasty >=0.12 && <2,\n    tasty-quickcheck >=0.9 && <0.12,\n";
  }