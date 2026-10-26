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
    flags = { pedantic = false; use-fingertree = true; };
    package = {
      specVersion = "2.4";
      identifier = { name = "hls-plugin-api"; version = "2.15.0.0"; };
      license = "Apache-2.0";
      copyright = "The Haskell IDE Team";
      maintainer = "alan.zimm@gmail.com";
      author = "The Haskell IDE Team";
      homepage = "https://github.com/haskell/haskell-language-server#readme";
      url = "";
      synopsis = "Haskell Language Server API for plugin communication";
      description = "Please see the README on GitHub at <https://github.com/haskell/haskell-language-server#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."co-log-core" or (errorHandler.buildDepError "co-log-core"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."dependent-map" or (errorHandler.buildDepError "dependent-map"))
          (hsPkgs."dependent-sum" or (errorHandler.buildDepError "dependent-sum"))
          (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
          (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
          (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
          (hsPkgs."lens-aeson" or (errorHandler.buildDepError "lens-aeson"))
          (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
          (hsPkgs."megaparsec" or (errorHandler.buildDepError "megaparsec"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."opentelemetry" or (errorHandler.buildDepError "opentelemetry"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
          (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
        ] ++ (if system.isWindows
          then [ (hsPkgs."Win32" or (errorHandler.buildDepError "Win32")) ]
          else [
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ])) ++ pkgs.lib.optional (flags.use-fingertree) (hsPkgs."hw-fingertree" or (errorHandler.buildDepError "hw-fingertree"));
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-rerun" or (errorHandler.buildDepError "tasty-rerun"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "rangemap-benchmark" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."random-fu" or (errorHandler.buildDepError "random-fu"))
          ];
          buildable = if !flags.use-fingertree then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hls-plugin-api-2.15.0.0.tar.gz";
      sha256 = "3e58cde686c87ccd4a88215cc2fb5a1589ad7ba405737fbb8a67f8e0d628a036";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\nname:          hls-plugin-api\nversion:       2.15.0.0\nsynopsis:      Haskell Language Server API for plugin communication\ndescription:\n  Please see the README on GitHub at <https://github.com/haskell/haskell-language-server#readme>\n\nhomepage:      https://github.com/haskell/haskell-language-server#readme\nbug-reports:   https://github.com/haskell/haskell-language-server/issues\nlicense:       Apache-2.0\nlicense-file:  LICENSE\nauthor:        The Haskell IDE Team\nmaintainer:    alan.zimm@gmail.com\ncopyright:     The Haskell IDE Team\ncategory:      Development\nbuild-type:    Simple\n\nflag pedantic\n  description: Enable -Werror\n  default:     False\n  manual:      True\n\n-- This flag can be used to avoid the dependency on hw-fingertree.\n-- We can set this temporarily if we have problems building hw-fingertree\n-- for a new version of GHC.\nflag use-fingertree\n  description: Use fingertree implementation of RangeMap\n  default:     True\n  manual:      False\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/haskell-language-server\n\ncommon warnings\n  ghc-options:\n    -Wall -Wredundant-constraints -Wunused-packages\n    -Wno-name-shadowing -Wno-unticked-promoted-constructors\n\nlibrary\n  import: warnings\n  exposed-modules:\n    Ide.Logger\n    Ide.Plugin.Config\n    Ide.Plugin.ConfigUtils\n    Ide.Plugin.Error\n    Ide.Plugin.HandleRequestTypes\n    Ide.Plugin.Properties\n    Ide.Plugin.RangeMap\n    Ide.Plugin.Resolve\n    Ide.PluginUtils\n    Ide.Types\n\n  hs-source-dirs:     src\n  build-depends:\n    , aeson\n    , base                  >=4.12    && <5\n    , co-log-core\n    , containers\n    , data-default\n    , dependent-map\n    , dependent-sum         >=0.7\n    , Diff                  ^>=0.5 || ^>=1.0.0\n    , dlist\n    , extra\n    , filepath\n    , ghc\n    , hashable\n    , hls-graph             == 2.15.0.0\n    , lens\n    , lens-aeson\n    , lsp                   ^>=2.8\n    , megaparsec            >=9.0\n    , mtl\n    , opentelemetry         >=0.4\n    , optparse-applicative\n    , prettyprinter\n    , regex-tdfa            >=1.3.1.0\n    , stm\n    , text\n    , time\n    , transformers\n    , unliftio\n    , unordered-containers\n\n  if os(windows)\n    build-depends: Win32\n\n  else\n    build-depends: unix\n\n  if flag(pedantic)\n    ghc-options: -Werror\n\n  if flag(use-fingertree)\n    cpp-options:   -DUSE_FINGERTREE\n    build-depends: hw-fingertree\n\n  default-language:   GHC2021\n  default-extensions:\n    DataKinds\n\ntest-suite tests\n  import: warnings\n  type:             exitcode-stdio-1.0\n  default-language: GHC2021\n  hs-source-dirs:   test\n  main-is:          Main.hs\n  ghc-options:      -threaded -rtsopts -with-rtsopts=-N\n  other-modules:\n    Ide.PluginUtilsTest\n    Ide.TypesTests\n\n  build-depends:\n    , bytestring\n    , aeson\n    , base\n    , containers\n    , data-default\n    , hls-plugin-api\n    , lens\n    , lsp-types\n    , tasty\n    , tasty-golden\n    , tasty-hunit\n    , tasty-quickcheck\n    , tasty-rerun\n    , text\n\nbenchmark rangemap-benchmark\n  import: warnings\n  -- Benchmark doesn't make sense if fingertree implementation\n  -- is not used.\n  if !flag(use-fingertree)\n    buildable: False\n\n  type:             exitcode-stdio-1.0\n  default-language: GHC2021\n  hs-source-dirs:   bench\n  main-is:          Main.hs\n  ghc-options:      -threaded\n  build-depends:\n    , base\n    , criterion\n    , deepseq\n    , hls-plugin-api\n    , lsp-types\n    , random\n    , random-fu\n";
  }