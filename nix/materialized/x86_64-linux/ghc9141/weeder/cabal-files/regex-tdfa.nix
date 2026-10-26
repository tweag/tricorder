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
    flags = { force-o2 = false; doctest = true; };
    package = {
      specVersion = "2.0";
      identifier = { name = "regex-tdfa"; version = "1.3.2.7"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (c) 2007-2009, Christopher Kuklewicz";
      maintainer = "Andreas Abel";
      author = "Christopher Kuklewicz";
      homepage = "https://wiki.haskell.org/Regular_expressions";
      url = "";
      synopsis = "Pure Haskell Tagged DFA Backend for \"Text.Regex\" (regex-base)";
      description = "This package provides a pure Haskell \\\"Tagged\\\" DFA regex engine for <//hackage.haskell.org/package/regex-base regex-base>. This implementation was inspired by the algorithm (and Master's thesis) behind the regular expression library known as <https://github.com/laurikari/tre/ TRE or libtre>.\n\nPlease consult the \"Text.Regex.TDFA\" module for API documentation including a tutorial with usage examples;\nsee also <https://wiki.haskell.org/Regular_expressions> for general information about regular expression support in Haskell.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."parsec" or (errorHandler.buildDepError "parsec"))
          (hsPkgs."regex-base" or (errorHandler.buildDepError "regex-base"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "regex-tdfa-unittest" = {
          depends = [
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."regex-base" or (errorHandler.buildDepError "regex-base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          ];
          buildable = true;
        };
        "doctest" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doctest-parallel" or (errorHandler.buildDepError "doctest-parallel"))
          ];
          buildable = if !flags.doctest then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/regex-tdfa-1.3.2.7.tar.gz";
      sha256 = "909b50d0cb703bbd8f0e627eda5d7101bcfc7c373205b2e1a2187e9accf9a862";
    });
  }) // {
    package-description-override = "cabal-version:          2.0\nname:                   regex-tdfa\nversion:                1.3.2.7\n\nbuild-Type:             Simple\nlicense:                BSD3\nlicense-file:           LICENSE\ncopyright:              Copyright (c) 2007-2009, Christopher Kuklewicz\nauthor:                 Christopher Kuklewicz\nmaintainer:             Andreas Abel\nhomepage:               https://wiki.haskell.org/Regular_expressions\nbug-reports:            https://github.com/haskell-hvr/regex-tdfa/issues\n\ncategory:               Text\nsynopsis:               Pure Haskell Tagged DFA Backend for \"Text.Regex\" (regex-base)\ndescription:\n  This package provides a pure Haskell \\\"Tagged\\\" DFA regex engine for <//hackage.haskell.org/package/regex-base regex-base>. This implementation was inspired by the algorithm (and Master's thesis) behind the regular expression library known as <https://github.com/laurikari/tre/ TRE or libtre>.\n  .\n  Please consult the \"Text.Regex.TDFA\" module for API documentation including a tutorial with usage examples;\n  see also <https://wiki.haskell.org/Regular_expressions> for general information about regular expression support in Haskell.\n\nextra-doc-files:\n  CHANGELOG.md\n  README.md\n\nextra-source-files:\n  test/cases/*.txt\n\ntested-with:\n  GHC == 10.0.1\n  GHC == 9.14.1\n  GHC == 9.12.4\n  GHC == 9.10.3\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n\nsource-repository head\n  type:                git\n  location:            https://github.com/haskell-hvr/regex-tdfa.git\n\nsource-repository this\n  type:                git\n  location:            https://github.com/haskell-hvr/regex-tdfa.git\n  tag:                 v1.3.2.7\n\nflag force-O2\n  default: False\n  manual: True\n  description:\n    Force building @regex-tdfa@ with \\\"@ghc-options: -O2@\\\".\n    .\n    __NOTE__: This flag is mostly provided for legacy use-cases. Nowadays you can conveniently control optimization levels on a per-package granularity via @cabal.project@ files; see <https://cabal.readthedocs.io/en/latest/nix-local-build.html#configuring-builds-with-cabal-project cabal's user-guide> for more details.\n\nflag doctest\n  default: True\n  manual: False\n  description:\n    Include test-suite doctest.\n\nlibrary\n  hs-source-dirs:       lib\n\n  exposed-modules:      Data.IntMap.CharMap2\n                        Data.IntMap.EnumMap2\n                        Data.IntSet.EnumSet2\n                        Text.Regex.TDFA\n                        Text.Regex.TDFA.ByteString\n                        Text.Regex.TDFA.ByteString.Lazy\n                        Text.Regex.TDFA.Common\n                        Text.Regex.TDFA.CorePattern\n                        Text.Regex.TDFA.IntArrTrieSet\n                        Text.Regex.TDFA.NewDFA.Engine\n                        Text.Regex.TDFA.NewDFA.Engine_FA\n                        Text.Regex.TDFA.NewDFA.Engine_NC\n                        Text.Regex.TDFA.NewDFA.Engine_NC_FA\n                        Text.Regex.TDFA.NewDFA.Tester\n                        Text.Regex.TDFA.NewDFA.Uncons\n                        Text.Regex.TDFA.NewDFA.MakeTest\n                        Text.Regex.TDFA.Pattern\n                        Text.Regex.TDFA.ReadRegex\n                        Text.Regex.TDFA.Sequence\n                        Text.Regex.TDFA.String\n                        Text.Regex.TDFA.TDFA\n                        Text.Regex.TDFA.TNFA\n                        Text.Regex.TDFA.Text\n                        Text.Regex.TDFA.Text.Lazy\n\n  autogen-modules:      Paths_regex_tdfa\n  other-modules:        Paths_regex_tdfa\n\n  build-depends:        array              >= 0.5    && < 0.6\n                      , base               >= 4.9    && < 5\n                      , bytestring         >= 0.10   && < 0.13\n                      , containers         >= 0.5    && < 1\n                          -- containers >= 0.5.11.0 (GHC 8.4) will allow to drop some #if\n                      , mtl                >= 2.1.3  && < 2.4\n                      , parsec             == 3.1.*\n                      , regex-base         == 0.94.*\n                      , text               >= 1.2.3  && < 2.2\n\n  default-language:     Haskell2010\n  default-extensions:   BangPatterns\n                        ExistentialQuantification\n                        FlexibleContexts\n                        FlexibleInstances\n                        ForeignFunctionInterface\n                        FunctionalDependencies\n                        MagicHash\n                        MultiParamTypeClasses\n                        NondecreasingIndentation\n                        RecursiveDo\n                        ScopedTypeVariables\n                        TypeOperators\n                        TypeSynonymInstances\n                        UnboxedTuples\n                        UnliftedFFITypes\n  other-extensions:     CPP\n\n  ghc-options:\n      -funbox-strict-fields\n      -fspec-constr-count=10\n      -Wall\n      -Wno-orphans\n      -Wcompat\n\n  if flag(force-O2)\n    ghc-options:\n      -O2\n\n\ntest-suite regex-tdfa-unittest\n  type:                 exitcode-stdio-1.0\n\n  hs-source-dirs:       test\n  main-is:              Main.hs\n\n  -- intra-package dependency\n  build-depends:        regex-tdfa\n\n  -- dependencies whose version constraints are inherited via intra-package 'regex-tdfa' dependency\n  build-depends:        array\n                      , base\n                      , bytestring\n                      , filepath\n                      , regex-base\n\n  -- component-specific dependencies not inherited via 'regex-tdfa'\n                      , directory          >= 1.1.0  && < 1.4\n                      , filepath           >= 1.3.0  && < 1.6\n                      , utf8-string        >= 1.0.1  && < 1.1\n\n  default-language:     Haskell2010\n  default-extensions:   FlexibleInstances\n                        FlexibleContexts\n                        Rank2Types\n  other-extensions:     GeneralizedNewtypeDeriving\n\n  ghc-options:          -funbox-strict-fields\n                        -Wall\n                        -Wcompat\n\n  if flag(force-O2)\n    ghc-options:        -O2\n\ntest-suite doctest\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: test\n  main-is:        DocTestMain.hs\n\n  build-depends:\n      base             >= 4.9    && < 5\n    , doctest-parallel >= 0.2.2\n        -- doctest-parallel-0.2.2 is the first to filter out autogen-modules\n\n  default-language:     Haskell2010\n\n  if !flag(doctest)\n    buildable: False\n";
  }