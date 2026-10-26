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
      specVersion = "2.4";
      identifier = { name = "co-log-core"; version = "0.3.2.7"; };
      license = "MPL-2.0";
      copyright = "2018-2020 Kowainik, 2021-2026 Co-Log";
      maintainer = "Co-Log <xrom.xkov@gmail.com>";
      author = "Dmitrii Kovanikov";
      homepage = "https://github.com/co-log/co-log-core";
      url = "";
      synopsis = "Composable Contravariant Comonadic Logging Library";
      description = "This package provides core types and functions to work with the @LogAction@ data type which is both simple and powerful.\n\n@\n__newtype__ LogAction m msg = LogAction\n\\    { unLogAction :: msg -> m ()\n\\    }\n@\n\nThe ideas behind this package are described in the following blog post:\n\n* [co-log: Composable Contravariant Combinatorial Comonadic Configurable Convenient Logging](https://kowainik.github.io/posts/2018-09-25-co-log)\n\nSee the following packages for different implementations based on @co-log-core@:\n\n* [co-log](http://hackage.haskell.org/package/co-log): taggless final implementations.\n* [co-log-polysemy](http://hackage.haskell.org/package/co-log-polysemy): extensible\neffects implementation based on @polysemy@.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
      tests = {
        "doctest" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doctest" or (errorHandler.buildDepError "doctest"))
            (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/co-log-core-0.3.2.7.tar.gz";
      sha256 = "c09abfbce74438d4418e6ed1e27726aa61d5a296ff6dfd42dafc0784b62a82a4";
    });
  }) // {
    package-description-override = "cabal-version:       2.4\nname:                co-log-core\nversion:             0.3.2.7\nsynopsis:            Composable Contravariant Comonadic Logging Library\ndescription:\n    This package provides core types and functions to work with the @LogAction@ data type which is both simple and powerful.\n    .\n    @\n    __newtype__ LogAction m msg = LogAction\n    \\    { unLogAction :: msg -> m ()\n    \\    }\n    @\n    .\n    The ideas behind this package are described in the following blog post:\n    .\n    * [co-log: Composable Contravariant Combinatorial Comonadic Configurable Convenient Logging](https://kowainik.github.io/posts/2018-09-25-co-log)\n    .\n    See the following packages for different implementations based on @co-log-core@:\n    .\n    * [co-log](http://hackage.haskell.org/package/co-log): taggless final implementations.\n    * [co-log-polysemy](http://hackage.haskell.org/package/co-log-polysemy): extensible\n      effects implementation based on @polysemy@.\n\nhomepage:            https://github.com/co-log/co-log-core\nbug-reports:         https://github.com/co-log/co-log-core/issues\nlicense:             MPL-2.0\nlicense-file:        LICENSE\nauthor:              Dmitrii Kovanikov\nmaintainer:          Co-Log <xrom.xkov@gmail.com>\ncopyright:           2018-2020 Kowainik, 2021-2026 Co-Log\ncategory:            Logging, Contravariant, Comonad\nbuild-type:          Simple\nstability:           stable\nextra-doc-files:     CHANGELOG.md\n                     README.md\ntested-with:         GHC == 8.2.2\n                     GHC == 8.4.4\n                     GHC == 8.6.5\n                     GHC == 8.8.4\n                     GHC == 8.10.7\n                     GHC == 9.0.2\n                     GHC == 9.2.8\n                     GHC == 9.4.8\n                     GHC == 9.6.7\n                     GHC == 9.8.4\n                     GHC == 9.10.3\n                     GHC == 9.12.2\n                     GHC == 9.14.1\n\nsource-repository head\n  type:                git\n  location:            https://github.com/co-log/co-log-core.git\n\ncommon common-options\n  build-depends:       base >= 4.10.1.0 && < 4.23\n\n  ghc-options:         -Wall\n                       -Wcompat\n                       -Widentities\n                       -Wincomplete-uni-patterns\n                       -Wincomplete-record-updates\n                       -Wredundant-constraints\n  if impl(ghc >= 8.2)\n    ghc-options:       -fhide-source-paths\n  if impl(ghc >= 8.4)\n    ghc-options:       -Wmissing-export-lists\n                       -Wpartial-fields\n  if impl(ghc >= 8.8)\n    ghc-options:       -Wmissing-deriving-strategies\n  if impl(ghc >= 8.10)\n    ghc-options:       -Wunused-packages\n  if impl(ghc >= 9.0)\n    ghc-options:       -Winvalid-haddock\n  if impl(ghc >= 9.2)\n    ghc-options:       -Wredundant-bang-patterns\n                       -Woperator-whitespace\n  if impl(ghc >= 9.4)\n    ghc-options:       -Wredundant-strictness-flags\n                       -Wforall-identifier\n\n  default-language:    Haskell2010\n  default-extensions:  ConstraintKinds\n                       DeriveFunctor\n                       DeriveTraversable\n                       DeriveGeneric\n                       DerivingStrategies\n                       GeneralizedNewtypeDeriving\n                       InstanceSigs\n                       LambdaCase\n                       OverloadedStrings\n                       RecordWildCards\n                       ScopedTypeVariables\n                       StandaloneDeriving\n                       TupleSections\n                       TypeApplications\n                       ViewPatterns\n\nlibrary\n  import:              common-options\n  hs-source-dirs:      src\n  exposed-modules:     Colog.Core\n                       Colog.Core.Action\n                       Colog.Core.Class\n                       Colog.Core.Severity\n                       Colog.Core.IO\n\ntest-suite doctest\n  import:               common-options\n  type:                 exitcode-stdio-1.0\n  hs-source-dirs:       test\n  main-is:              Doctests.hs\n  build-depends:        doctest >= 0.16.0 && < 1.0.0\n                      , Glob ^>= 0.10.0\n";
  }