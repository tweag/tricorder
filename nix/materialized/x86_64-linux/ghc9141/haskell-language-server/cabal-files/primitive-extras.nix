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
      identifier = { name = "primitive-extras"; version = "0.10.2.2"; };
      license = "MIT";
      copyright = "(c) 2018, Metrix.AI";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/primitive-extras";
      url = "";
      synopsis = "Extras for the \"primitive\" library";
      description = "Raw collection of extra utiltilies for the \"primitive\" library.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
          (hsPkgs."deferred-folds" or (errorHandler.buildDepError "deferred-folds"))
          (hsPkgs."focus" or (errorHandler.buildDepError "focus"))
          (hsPkgs."foldl" or (errorHandler.buildDepError "foldl"))
          (hsPkgs."list-t" or (errorHandler.buildDepError "list-t"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."primitive-unlifted" or (errorHandler.buildDepError "primitive-unlifted"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
            (hsPkgs."deferred-folds" or (errorHandler.buildDepError "deferred-folds"))
            (hsPkgs."focus" or (errorHandler.buildDepError "focus"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."primitive-extras" or (errorHandler.buildDepError "primitive-extras"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
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
      url = "http://hackage.haskell.org/package/primitive-extras-0.10.2.2.tar.gz";
      sha256 = "c4add825d820bc680dcf2895c181aa0d973daad1e7827fd2b91bc738932d3825";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: primitive-extras\nsynopsis: Extras for the \"primitive\" library\ndescription:\n  Raw collection of extra utiltilies for the \"primitive\" library.\n\nversion: 0.10.2.2\ncategory: Primitive\nhomepage: https://github.com/nikita-volkov/primitive-extras\nbug-reports: https://github.com/nikita-volkov/primitive-extras/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2018, Metrix.AI\nlicense: MIT\nlicense-file: LICENSE\n\nsource-repository head\n  type: git\n  location: git://github.com/nikita-volkov/primitive-extras.git\n\nlibrary\n  hs-source-dirs: library\n  default-extensions:\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\n  default-language: Haskell2010\n  exposed-modules:\n    PrimitiveExtras.Bitmap\n    PrimitiveExtras.By6Bits\n    PrimitiveExtras.PrimArray\n    PrimitiveExtras.PrimMultiArray\n    PrimitiveExtras.SmallArray\n    PrimitiveExtras.UnliftedArray\n\n  other-modules:\n    PrimitiveExtras.FoldMs\n    PrimitiveExtras.Folds\n    PrimitiveExtras.Prelude\n    PrimitiveExtras.Types\n\n  build-depends:\n    base >=4.7 && <5,\n    bytestring >=0.10 && <0.13,\n    cereal >=0.5.5 && <0.6,\n    deferred-folds >=0.9 && <0.10,\n    focus >=1 && <1.1,\n    foldl >=1 && <2,\n    list-t >=1.0.1 && <1.1,\n    primitive >=0.7 && <0.10,\n    primitive-unlifted >=0.1.3.1 && <0.2 || >=2.1 && <2.3,\n    profunctors >=5 && <6,\n    vector >=0.12 && <0.14,\n\ntest-suite test\n  type: exitcode-stdio-1.0\n  hs-source-dirs: test\n  main-is: Main.hs\n  default-extensions:\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\n  default-language: Haskell2010\n  other-modules:\n    Main.Gens\n    Main.Transaction\n\n  build-depends:\n    QuickCheck >=2.13.1 && <3,\n    cereal,\n    deferred-folds,\n    focus,\n    primitive,\n    primitive-extras,\n    rerebase <2,\n    tasty >=1.2.2 && <2,\n    tasty-hunit >=0.10.0.2 && <0.11,\n    tasty-quickcheck >=0.10.1 && <0.12,\n";
  }