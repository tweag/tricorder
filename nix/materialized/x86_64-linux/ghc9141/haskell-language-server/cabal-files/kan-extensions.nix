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
      specVersion = "1.10";
      identifier = { name = "kan-extensions"; version = "5.2.8"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2008-2016 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/kan-extensions/";
      url = "";
      synopsis = "Kan extensions, Kan lifts, the Yoneda lemma, and (co)density (co)monads";
      description = "Kan extensions, Kan lifts, various forms of the Yoneda lemma, and (co)density (co)monads.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."adjunctions" or (errorHandler.buildDepError "adjunctions"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."comonad" or (errorHandler.buildDepError "comonad"))
          (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"))
          (hsPkgs."distributive" or (errorHandler.buildDepError "distributive"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."invariant" or (errorHandler.buildDepError "invariant"))
          (hsPkgs."free" or (errorHandler.buildDepError "free"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."semigroupoids" or (errorHandler.buildDepError "semigroupoids"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/kan-extensions-5.2.8.tar.gz";
      sha256 = "f76daa44a80d423c849d5fb552e2a20b1e2f47b638c889a34cb1a5bd1ab08d21";
    });
  }) // {
    package-description-override = "name:          kan-extensions\ncategory:      Data Structures, Monads, Comonads, Functors\nversion:       5.2.8\nlicense:       BSD3\ncabal-version: >= 1.10\nlicense-file:  LICENSE\nauthor:        Edward A. Kmett\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\nstability:     provisional\nhomepage:      http://github.com/ekmett/kan-extensions/\nbug-reports:   http://github.com/ekmett/kan-extensions/issues\ncopyright:     Copyright (C) 2008-2016 Edward A. Kmett\nsynopsis:      Kan extensions, Kan lifts, the Yoneda lemma, and (co)density (co)monads\ndescription:   Kan extensions, Kan lifts, various forms of the Yoneda lemma, and (co)density (co)monads.\nbuild-type:    Simple\ntested-with:   GHC == 8.4.4\n             , GHC == 8.6.5\n             , GHC == 8.8.4\n             , GHC == 8.10.7\n             , GHC == 9.0.2\n             , GHC == 9.2.8\n             , GHC == 9.4.8\n             , GHC == 9.6.7\n             , GHC == 9.8.4\n             , GHC == 9.10.3\n             , GHC == 9.12.2\n             , GHC == 9.14.1\n\nextra-source-files:\n  .gitignore\n  .vim.custom\n  CHANGELOG.markdown\n  README.markdown\n\nsource-repository head\n  type: git\n  location: https://github.com/ekmett/kan-extensions.git\n\nlibrary\n  hs-source-dirs: src\n\n  other-extensions:\n    CPP\n    MultiParamTypeClasses\n    GADTs\n    Rank2Types,\n    FlexibleInstances\n    FlexibleContexts\n    UndecidableInstances\n    TypeFamilies\n\n  build-depends:\n    adjunctions         >= 4.2     && < 5,\n    base                >= 4.11    && < 5,\n    comonad             >= 4       && < 6,\n    contravariant       >= 1       && < 2,\n    distributive        >= 0.2.2   && < 1,\n    exceptions          >= 0.10    && < 0.11,\n    invariant           >= 0.1     && < 1,\n    free                >= 4       && < 6,\n    mtl                 >= 2.2.1   && < 2.4,\n    profunctors         >= 5       && < 6,\n    semigroupoids       >= 5.2.2   && < 7,\n    transformers        >= 0.5     && < 0.7\n\n  exposed-modules:\n    Control.Comonad.Density\n    Control.Monad.Co\n    Control.Monad.Codensity\n    Data.Functor.Contravariant.Day\n    Data.Functor.Contravariant.Yoneda\n    Data.Functor.Contravariant.Coyoneda\n    Data.Functor.Day\n    Data.Functor.Day.Curried\n    Data.Functor.Invariant.Day\n    Data.Functor.Kan.Lan\n    Data.Functor.Kan.Ran\n    Data.Functor.Yoneda\n    Data.Functor.Coyoneda\n\n  ghc-options: -Wall -Wcompat -Wnoncanonical-monad-instances -Wno-trustworthy-safe\n  if !impl(ghc >= 8.8)\n    ghc-options: -Wnoncanonical-monadfail-instances\n\n  default-language: Haskell2010\n";
  }