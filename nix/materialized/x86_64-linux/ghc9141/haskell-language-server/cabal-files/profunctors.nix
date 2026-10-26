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
      identifier = { name = "profunctors"; version = "5.6.3"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2011-2015 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/profunctors/";
      url = "";
      synopsis = "Profunctors";
      description = "Profunctors.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"))
          (hsPkgs."bifunctors" or (errorHandler.buildDepError "bifunctors"))
          (hsPkgs."comonad" or (errorHandler.buildDepError "comonad"))
          (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"))
          (hsPkgs."distributive" or (errorHandler.buildDepError "distributive"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/profunctors-5.6.3.tar.gz";
      sha256 = "b9c6f427368d2e811e4c48b59005218672458fd2f00a02cbefb8be9c751c0ef3";
    });
  }) // {
    package-description-override = "name:          profunctors\ncategory:      Control, Categories\nversion:       5.6.3\nlicense:       BSD3\ncabal-version: >= 1.10\nlicense-file:  LICENSE\nauthor:        Edward A. Kmett\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\nstability:     experimental\nhomepage:      http://github.com/ekmett/profunctors/\nbug-reports:   http://github.com/ekmett/profunctors/issues\ncopyright:     Copyright (C) 2011-2015 Edward A. Kmett\nsynopsis:      Profunctors\ndescription:   Profunctors.\ntested-with:   GHC == 8.0.2\n             , GHC == 8.2.2\n             , GHC == 8.4.4\n             , GHC == 8.6.5\n             , GHC == 8.8.4\n             , GHC == 8.10.7\n             , GHC == 9.0.2\n             , GHC == 9.2.8\n             , GHC == 9.4.8\n             , GHC == 9.6.6\n             , GHC == 9.8.4\n             , GHC == 9.10.1\n             , GHC == 9.12.2\nbuild-type:    Simple\nextra-source-files:\n  .ghci\n  .gitignore\n  .hlint.yaml\n  .vim.custom\n  README.markdown\n  CHANGELOG.markdown\n\nsource-repository head\n  type: git\n  location: https://github.com/ekmett/profunctors.git\n\nlibrary\n  build-depends:\n    base                >= 4.9     && < 5,\n    base-orphans        >= 0.8.4   && < 0.10,\n    bifunctors          >= 5.5.9   && < 6,\n    comonad             >= 5.0.8   && < 6,\n    contravariant       >= 1.5.3   && < 2,\n    distributive        >= 0.5.2   && < 1,\n    tagged              >= 0.8.6.1 && < 1,\n    transformers        >= 0.3     && < 0.7\n  exposed-modules:\n    Data.Profunctor\n    Data.Profunctor.Adjunction\n    Data.Profunctor.Cayley\n    Data.Profunctor.Choice\n    Data.Profunctor.Closed\n    Data.Profunctor.Composition\n    Data.Profunctor.Mapping\n    Data.Profunctor.Monad\n    Data.Profunctor.Ran\n    Data.Profunctor.Rep\n    Data.Profunctor.Sieve\n    Data.Profunctor.Strong\n    Data.Profunctor.Traversing\n    Data.Profunctor.Types\n    Data.Profunctor.Unsafe\n    Data.Profunctor.Yoneda\n\n  ghc-options:     -Wall -O2 -Wno-trustworthy-safe\n\n  if impl(ghc >= 8.6)\n    ghc-options: -Wno-star-is-type\n\n  if impl(ghc >= 9.0)\n    -- these flags may abort compilation with GHC-8.10\n    -- https://gitlab.haskell.org/ghc/ghc/-/merge_requests/3295\n    ghc-options: -Winferred-safe-imports -Wmissing-safe-haskell-mode\n\n  hs-source-dirs:  src\n\n  default-language: Haskell2010\n  other-extensions:\n    CPP\n    GADTs\n    FlexibleContexts\n    FlexibleInstances\n    InstanceSigs\n    UndecidableInstances\n    TypeFamilies\n";
  }