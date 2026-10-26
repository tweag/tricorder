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
      specVersion = "1.18";
      identifier = { name = "free"; version = "5.2"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2008-2015 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/free/";
      url = "";
      synopsis = "Monads for free";
      description = "Free monads are useful for many tree-like structures and domain specific languages.\n\nIf @f@ is a 'Functor' then the free 'Monad' on @f@ is the type\nof trees whose nodes are labeled with the constructors of @f@. The word\n\\\"free\\\" is used in the sense of \\\"unrestricted\\\" rather than \\\"zero-cost\\\":\n@Free f@ makes no constraining assumptions beyond those given by @f@ and the\ndefinition of 'Monad'. As used here it is a standard term from the\nmathematical theory of adjoint functors.\n\nCofree comonads are dual to free monads. They provide convenient ways to talk\nabout branching streams and rose-trees, and can be used to annotate syntax\ntrees. The cofree comonad can be seen as a stream parameterized by a 'Functor'\nthat controls its branching factor.\n\nMore information on free monads, including examples, can be found in the\nfollowing blog posts:\n<https://ekmett.github.io/reader/2008/monads-for-free/>\n<https://ekmett.github.io/reader/2011/free-monads-for-less/>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."comonad" or (errorHandler.buildDepError "comonad"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."distributive" or (errorHandler.buildDepError "distributive"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."indexed-traversable" or (errorHandler.buildDepError "indexed-traversable"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."semigroupoids" or (errorHandler.buildDepError "semigroupoids"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "8.2")) (hsPkgs."bifunctor-classes-compat" or (errorHandler.buildDepError "bifunctor-classes-compat"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/free-5.2.tar.gz";
      sha256 = "72867f7c89173263765736e8d395e94291f1aaea626ecb1d673d72ce90b94f89";
    });
  }) // {
    package-description-override = "name:          free\r\ncategory:      Control, Monads\r\nversion:       5.2\r\nx-revision: 8\r\nlicense:       BSD3\r\ncabal-version: 1.18\r\nlicense-file:  LICENSE\r\nauthor:        Edward A. Kmett\r\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\r\nstability:     provisional\r\nhomepage:      http://github.com/ekmett/free/\r\nbug-reports:   http://github.com/ekmett/free/issues\r\ncopyright:     Copyright (C) 2008-2015 Edward A. Kmett\r\ntested-with:   GHC == 8.0.2\r\n             , GHC == 8.2.2\r\n             , GHC == 8.4.4\r\n             , GHC == 8.6.5\r\n             , GHC == 8.8.4\r\n             , GHC == 8.10.7\r\n             , GHC == 9.0.2\r\n             , GHC == 9.2.6\r\n             , GHC == 9.4.4\r\n             , GHC == 9.6.1\r\nsynopsis:      Monads for free\r\ndescription:\r\n  Free monads are useful for many tree-like structures and domain specific languages.\r\n  .\r\n  If @f@ is a 'Functor' then the free 'Monad' on @f@ is the type\r\n  of trees whose nodes are labeled with the constructors of @f@. The word\r\n  \\\"free\\\" is used in the sense of \\\"unrestricted\\\" rather than \\\"zero-cost\\\":\r\n  @Free f@ makes no constraining assumptions beyond those given by @f@ and the\r\n  definition of 'Monad'. As used here it is a standard term from the\r\n  mathematical theory of adjoint functors.\r\n  .\r\n  Cofree comonads are dual to free monads. They provide convenient ways to talk\r\n  about branching streams and rose-trees, and can be used to annotate syntax\r\n  trees. The cofree comonad can be seen as a stream parameterized by a 'Functor'\r\n  that controls its branching factor.\r\n  .\r\n  More information on free monads, including examples, can be found in the\r\n  following blog posts:\r\n  <https://ekmett.github.io/reader/2008/monads-for-free/>\r\n  <https://ekmett.github.io/reader/2011/free-monads-for-less/>\r\n\r\nbuild-type:    Simple\r\nextra-source-files:\r\n  .gitignore\r\n  .hlint.yaml\r\n  .vim.custom\r\n  README.markdown\r\n  CHANGELOG.markdown\r\n  doc/proof/Control/Comonad/Cofree/*.md\r\n  doc/proof/Control/Comonad/Trans/Cofree/*.md\r\n  examples/free-examples.cabal\r\n  examples/LICENSE\r\n  examples/*.hs\r\n  examples/*.lhs\r\nextra-doc-files:\r\n  examples/*.hs\r\n  examples/*.lhs\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/ekmett/free.git\r\n\r\nlibrary\r\n  hs-source-dirs: src\r\n\r\n  default-language:   Haskell2010\r\n  other-extensions:\r\n    MultiParamTypeClasses\r\n    FunctionalDependencies\r\n    FlexibleInstances\r\n    UndecidableInstances\r\n    Rank2Types\r\n    GADTs\r\n\r\n  build-depends:\r\n    base                 >= 4.9     && < 5,\r\n    comonad              >= 5.0.8   && < 6,\r\n    containers           >= 0.5.7.1 && < 0.9,\r\n    distributive         >= 0.5.2   && < 1,\r\n    exceptions           >= 0.10.4  && < 0.11,\r\n    indexed-traversable  >= 0.1.1   && < 0.2,\r\n    mtl                  >= 2.2.2   && < 2.4,\r\n    profunctors          >= 5.6.1   && < 6,\r\n    semigroupoids        >= 5.3.5   && < 7,\r\n    th-abstraction       >= 0.4.2.0 && < 0.8,\r\n    transformers         >= 0.5     && < 0.7,\r\n    transformers-base    >= 0.4.5.2 && < 0.5,\r\n    template-haskell     >= 2.11    && < 2.25\r\n\r\n  if !impl(ghc >= 8.2)\r\n    build-depends: bifunctor-classes-compat >= 0.1 && < 0.2\r\n\r\n  exposed-modules:\r\n    Control.Applicative.Free\r\n    Control.Applicative.Free.Fast\r\n    Control.Applicative.Free.Final\r\n    Control.Applicative.Trans.Free\r\n    Control.Alternative.Free\r\n    Control.Alternative.Free.Final\r\n    Control.Comonad.Cofree\r\n    Control.Comonad.Cofree.Class\r\n    Control.Comonad.Trans.Cofree\r\n    Control.Comonad.Trans.Coiter\r\n    Control.Monad.Free\r\n    Control.Monad.Free.Ap\r\n    Control.Monad.Free.Church\r\n    Control.Monad.Free.Class\r\n    Control.Monad.Free.TH\r\n    Control.Monad.Trans.Free\r\n    Control.Monad.Trans.Free.Ap\r\n    Control.Monad.Trans.Free.Church\r\n    Control.Monad.Trans.Iter\r\n\r\n  ghc-options: -Wall -Wcompat -Wnoncanonical-monad-instances\r\n\r\n  if !impl(ghc >= 8.8)\r\n    ghc-options: -Wnoncanonical-monadfail-instances\r\n\r\n  if impl(ghc >= 9.0)\r\n    -- these flags may abort compilation with GHC-8.10\r\n    -- https://gitlab.haskell.org/ghc/ghc/-/merge_requests/3295\r\n    ghc-options: -Winferred-safe-imports -Wmissing-safe-haskell-mode\r\n\r\n  x-docspec-extra-packages: tagged\r\n";
  }