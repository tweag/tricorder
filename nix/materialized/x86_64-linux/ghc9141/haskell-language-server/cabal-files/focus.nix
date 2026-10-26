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
      identifier = { name = "focus"; version = "1.0.3.2"; };
      license = "MIT";
      copyright = "(c) 2014, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/focus";
      url = "";
      synopsis = "A general abstraction for manipulating elements of container data structures";
      description = "An API for construction of free-form strategies of access and manipulation of \nelements of arbitrary data structures.\nIt allows to implement efficient composite patterns, e.g., \na simultaneous update and lookup of an element, \nand even more complex things.\nStrategies are meant to be interpreted by the host data structure libraries.\nThus they allow to implement all access and modification patterns of\na data structure with just a single function,\nwhich interprets strategies.\nThis library provides pure and monadic interfaces,\nso it supports both immutable and mutable data structures.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."focus" or (errorHandler.buildDepError "focus"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/focus-1.0.3.2.tar.gz";
      sha256 = "e24b3f0438810302472697ab10280d1ec53bbc98c1ef6812c450301a016cc286";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname:          focus\nversion:       1.0.3.2\nsynopsis:\n  A general abstraction for manipulating elements of container data structures\n\ndescription:\n  An API for construction of free-form strategies of access and manipulation of \n  elements of arbitrary data structures.\n  It allows to implement efficient composite patterns, e.g., \n  a simultaneous update and lookup of an element, \n  and even more complex things.\n  Strategies are meant to be interpreted by the host data structure libraries.\n  Thus they allow to implement all access and modification patterns of\n  a data structure with just a single function,\n  which interprets strategies.\n  This library provides pure and monadic interfaces,\n  so it supports both immutable and mutable data structures.\n\ncategory:      Containers, Data\nhomepage:      https://github.com/nikita-volkov/focus\nbug-reports:   https://github.com/nikita-volkov/focus/issues\nauthor:        Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer:    Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright:     (c) 2014, Nikita Volkov\nlicense:       MIT\nlicense-file:  LICENSE\n\nsource-repository head\n  type:     git\n  location: git://github.com/nikita-volkov/focus.git\n\ncommon language-settings\n  default-extensions:\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    ApplicativeDo\n    BangPatterns\n    BinaryLiterals\n    BlockArguments\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    DerivingVia\n    DuplicateRecordFields\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    HexFloatLiterals\n    LambdaCase\n    LiberalTypeSynonyms\n    MultiParamTypeClasses\n    MultiWayIf\n    NumericUnderscores\n    OverloadedLabels\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    PatternSynonyms\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    StrictData\n    TemplateHaskell\n    TupleSections\n    TypeApplications\n    TypeFamilies\n    TypeOperators\n    UndecidableInstances\n    ViewPatterns\n\n  default-language:   Haskell2010\n\nlibrary\n  import:          language-settings\n  hs-source-dirs:  library\n  exposed-modules: Focus\n  other-modules:   Focus.Prelude\n  build-depends:\n    , base >=4.11 && <5\n    , transformers >=0.5 && <0.7\n\ntest-suite test\n  import:         language-settings\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: test\n  main-is:        Main.hs\n  build-depends:\n    , focus\n    , rerebase <2\n    , tasty >=0.12 && <2\n    , tasty-hunit >=0.9 && <0.11\n";
  }