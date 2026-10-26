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
      identifier = { name = "list-t"; version = "1.0.5.7"; };
      license = "MIT";
      copyright = "(c) 2014, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/list-t";
      url = "";
      synopsis = "ListT done right";
      description = "A correct implementation of the list monad-transformer.\nUseful for basic streaming.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."foldl" or (errorHandler.buildDepError "foldl"))
          (hsPkgs."logict" or (errorHandler.buildDepError "logict"))
          (hsPkgs."mmorph" or (errorHandler.buildDepError "mmorph"))
          (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.0") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
        buildable = true;
      };
      tests = {
        "htf-test" = {
          depends = [
            (hsPkgs."base-prelude" or (errorHandler.buildDepError "base-prelude"))
            (hsPkgs."HTF" or (errorHandler.buildDepError "HTF"))
            (hsPkgs."list-t" or (errorHandler.buildDepError "list-t"))
            (hsPkgs."mmorph" or (errorHandler.buildDepError "mmorph"))
            (hsPkgs."mtl-prelude" or (errorHandler.buildDepError "mtl-prelude"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/list-t-1.0.5.7.tar.gz";
      sha256 = "40928967728c7c96363309b372f415ca1729de0951c78ea1fa37f839687d6b46";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname:          list-t\nversion:       1.0.5.7\nsynopsis:      ListT done right\ndescription:\n  A correct implementation of the list monad-transformer.\n  Useful for basic streaming.\n\ncategory:      Streaming, Data Structures, Control\nhomepage:      https://github.com/nikita-volkov/list-t\nbug-reports:   https://github.com/nikita-volkov/list-t/issues\nauthor:        Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer:    Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright:     (c) 2014, Nikita Volkov\nlicense:       MIT\nlicense-file:  LICENSE\n\nsource-repository head\n  type:     git\n  location: git://github.com/nikita-volkov/list-t.git\n\ncommon language-settings\n  default-extensions:\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    PolyKinds\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n    UndecidableInstances\n\n  default-language:   Haskell2010\n\nlibrary\n  import:          language-settings\n  hs-source-dirs:  library\n  exposed-modules: ListT\n  other-modules:   ListT.Prelude\n  build-depends:\n    , base >=4.11 && <5\n    , foldl >=1.2 && <2\n    , logict >=0.7 && <0.9\n    , mmorph >=1 && <2\n    , monad-control >=0.3 && <2\n    , mtl >=2 && <3\n    , transformers >=0.3 && <0.7\n    , transformers-base ^>=0.4\n\n  if impl(ghc <8.0)\n    build-depends: semigroups >=0.11 && <0.21\n\ntest-suite htf-test\n  import:         language-settings\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: htf-test\n  main-is:        Main.hs\n  build-depends:\n    , base-prelude\n    , HTF ^>=0.15\n    , list-t\n    , mmorph\n    , mtl-prelude <3\n";
  }