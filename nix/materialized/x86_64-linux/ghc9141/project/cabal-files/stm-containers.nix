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
      identifier = { name = "stm-containers"; version = "1.2.2"; };
      license = "MIT";
      copyright = "(c) 2014, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/stm-containers";
      url = "";
      synopsis = "Containers for STM";
      description = "This library is based on an STM-specialized implementation of\nHash Array Mapped Trie.\nIt provides efficient implementations of @Map@, @Set@\nand other data structures,\nwhich starting from version @1@ perform even better than their counterparts from \\\"unordered-containers\\\",\nbut also scale well on concurrent access patterns.\n.\nFor details on performance of the library, which are a bit outdated, see\n<http://nikita-volkov.github.io/stm-containers/ this blog post>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deferred-folds" or (errorHandler.buildDepError "deferred-folds"))
          (hsPkgs."focus" or (errorHandler.buildDepError "focus"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."list-t" or (errorHandler.buildDepError "list-t"))
          (hsPkgs."stm-hamt" or (errorHandler.buildDepError "stm-hamt"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."deferred-folds" or (errorHandler.buildDepError "deferred-folds"))
            (hsPkgs."focus" or (errorHandler.buildDepError "focus"))
            (hsPkgs."foldl" or (errorHandler.buildDepError "foldl"))
            (hsPkgs."free" or (errorHandler.buildDepError "free"))
            (hsPkgs."list-t" or (errorHandler.buildDepError "list-t"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
            (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/stm-containers-1.2.2.tar.gz";
      sha256 = "6421b7393b0b509b16637747a566a1a2b1a0f492f88516bb04c38112452e0596";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: stm-containers\nversion: 1.2.2\nsynopsis: Containers for STM\ndescription:\n  This library is based on an STM-specialized implementation of\n  Hash Array Mapped Trie.\n  It provides efficient implementations of @Map@, @Set@\n  and other data structures,\n  which starting from version @1@ perform even better than their counterparts from \\\"unordered-containers\\\",\n  but also scale well on concurrent access patterns.\n  .\n  For details on performance of the library, which are a bit outdated, see\n  <http://nikita-volkov.github.io/stm-containers/ this blog post>.\n\ncategory: Data Structures, STM, Concurrency\nhomepage: https://github.com/nikita-volkov/stm-containers\nbug-reports: https://github.com/nikita-volkov/stm-containers/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2014, Nikita Volkov\nlicense: MIT\nlicense-file: LICENSE\n\nsource-repository head\n  type: git\n  location: https://github.com/nikita-volkov/stm-containers\n\nlibrary\n  hs-source-dirs: library\n  default-extensions:\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    PatternSynonyms\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeApplications\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\n  default-language: Haskell2010\n  exposed-modules:\n    StmContainers.Bimap\n    StmContainers.Map\n    StmContainers.Multimap\n    StmContainers.Set\n\n  other-modules: StmContainers.Prelude\n  build-depends:\n    base >=4.9 && <5,\n    deferred-folds >=0.9 && <0.10,\n    focus >=1.0.1.4 && <1.1,\n    hashable >=1.4 && <2,\n    list-t >=1.0.1 && <1.1,\n    stm-hamt >=1.2.2 && <1.3,\n    transformers >=0.5 && <0.7,\n\ntest-suite test\n  type: exitcode-stdio-1.0\n  hs-source-dirs: test\n  default-extensions:\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    PatternSynonyms\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeApplications\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\n  default-language: Haskell2010\n  main-is: Main.hs\n  other-modules:\n    Suites.Bimap\n    Suites.Map\n    Suites.Map.Update\n    Suites.Set\n\n  build-depends:\n    deferred-folds,\n    focus,\n    foldl >=1.4 && <2,\n    free >=4.6 && <6,\n    list-t,\n    quickcheck-instances >=0.3.29.1 && <0.4,\n    rerebase >=1 && <2,\n    stm-containers,\n    tasty >=0.12 && <2,\n    tasty-hunit >=0.10.0.3 && <0.11,\n    tasty-quickcheck >=0.10.2 && <0.12,\n";
  }