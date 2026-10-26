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
      identifier = { name = "stm-hamt"; version = "1.2.2.1"; };
      license = "MIT";
      copyright = "(c) 2016, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/stm-hamt";
      url = "";
      synopsis = "STM-specialised Hash Array Mapped Trie";
      description = "A low-level data-structure,\nwhich can be used to implement higher-level interfaces like\nhash-map and hash-set.\nSuch implementations are presented by the\n<http://hackage.haskell.org/package/stm-containers stm-containers>.";
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
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."primitive-extras" or (errorHandler.buildDepError "primitive-extras"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."deferred-folds" or (errorHandler.buildDepError "deferred-folds"))
            (hsPkgs."focus" or (errorHandler.buildDepError "focus"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
            (hsPkgs."stm-hamt" or (errorHandler.buildDepError "stm-hamt"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "concurrent-insertion-bench" = {
          depends = [
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."focus" or (errorHandler.buildDepError "focus"))
            (hsPkgs."free" or (errorHandler.buildDepError "free"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."rebase" or (errorHandler.buildDepError "rebase"))
            (hsPkgs."stm-hamt" or (errorHandler.buildDepError "stm-hamt"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/stm-hamt-1.2.2.1.tar.gz";
      sha256 = "3eb48a02954843ed3d34f13b66a435d2bd95fa18c5909d3b936ec481ec32cc8f";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: stm-hamt\nversion: 1.2.2.1\nsynopsis: STM-specialised Hash Array Mapped Trie\ndescription:\n  A low-level data-structure,\n  which can be used to implement higher-level interfaces like\n  hash-map and hash-set.\n  Such implementations are presented by the\n  <http://hackage.haskell.org/package/stm-containers stm-containers>.\n\ncategory: Data Structures, STM, Concurrency\nhomepage: https://github.com/nikita-volkov/stm-hamt\nbug-reports: https://github.com/nikita-volkov/stm-hamt/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2016, Nikita Volkov\nlicense: MIT\nlicense-file: LICENSE\n\ncommon base\n  default-language: Haskell2010\n  default-extensions:\n    Arrows\n    BangPatterns\n    BinaryLiterals\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\nlibrary\n  import: base\n  hs-source-dirs: library\n  exposed-modules:\n    StmHamt.Hamt\n    StmHamt.SizedHamt\n\n  other-modules:\n    StmHamt.Constructors.Branch\n    StmHamt.Focuses\n    StmHamt.IntOps\n    StmHamt.ListT\n    StmHamt.Prelude\n    StmHamt.Types\n    StmHamt.UnfoldlM\n\n  build-depends:\n    base >=4.9 && <5,\n    deferred-folds >=0.9 && <0.10,\n    focus >=1 && <1.1,\n    hashable >=1.4.0.0 && <2,\n    list-t >=1.0.1 && <1.1,\n    primitive >=0.7 && <0.10,\n    primitive-extras >=0.10.2 && <0.11,\n    transformers >=0.5 && <0.7,\n\ntest-suite test\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: test\n  main-is: Main.hs\n  other-modules:\n    Main.Gens\n    Main.Transaction\n\n  build-depends:\n    QuickCheck >=2.8.1 && <3,\n    deferred-folds,\n    focus,\n    quickcheck-instances >=0.3.11 && <0.5,\n    rerebase <2,\n    stm-hamt,\n    tasty >=0.12 && <2,\n    tasty-hunit >=0.9 && <0.11,\n    tasty-quickcheck >=0.9 && <0.12,\n\nbenchmark concurrent-insertion-bench\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: concurrent-insertion-bench\n  ghc-options:\n    -O2\n    -threaded\n    -with-rtsopts=-N\n\n  main-is: Main.hs\n  build-depends:\n    async >=2.0 && <3,\n    criterion >=1.5 && <1.7,\n    focus,\n    free >=4.5 && <6,\n    random >=1.2 && <2,\n    rebase <2,\n    stm-hamt,\n";
  }