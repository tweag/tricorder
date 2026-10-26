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
    flags = { pedantic = false; embed-files = false; stm-stats = false; };
    package = {
      specVersion = "2.4";
      identifier = { name = "hls-graph"; version = "2.15.0.0"; };
      license = "Apache-2.0";
      copyright = "The Haskell IDE Team";
      maintainer = "The Haskell IDE Team";
      author = "The Haskell IDE Team";
      homepage = "https://github.com/haskell/haskell-language-server#readme";
      url = "";
      synopsis = "Haskell Language Server internal graph API";
      description = "Please see the README on GitHub at <https://github.com/haskell/haskell-language-server/tree/master/hls-graph#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."focus" or (errorHandler.buildDepError "focus"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."js-dgtable" or (errorHandler.buildDepError "js-dgtable"))
          (hsPkgs."js-flot" or (errorHandler.buildDepError "js-flot"))
          (hsPkgs."js-jquery" or (errorHandler.buildDepError "js-jquery"))
          (hsPkgs."list-t" or (errorHandler.buildDepError "list-t"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
        ] ++ (if flags.embed-files
          then [
            (hsPkgs."file-embed" or (errorHandler.buildDepError "file-embed"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ]
          else [
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          ]);
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hspec" or (errorHandler.buildDepError "tasty-hspec"))
            (hsPkgs."tasty-rerun" or (errorHandler.buildDepError "tasty-rerun"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hls-graph-2.15.0.0.tar.gz";
      sha256 = "80533597e0b0e8cc3202a135e820275d2faa7a1e048e0983f251696228df2b6e";
    });
  }) // {
    package-description-override = "cabal-version:      2.4\nname:               hls-graph\nversion:            2.15.0.0\nsynopsis:           Haskell Language Server internal graph API\ndescription:\n  Please see the README on GitHub at <https://github.com/haskell/haskell-language-server/tree/master/hls-graph#readme>\n\nhomepage:           https://github.com/haskell/haskell-language-server#readme\nbug-reports:        https://github.com/haskell/haskell-language-server/issues\nlicense:            Apache-2.0\nlicense-file:       LICENSE\nauthor:             The Haskell IDE Team\nmaintainer:         The Haskell IDE Team\ncopyright:          The Haskell IDE Team\ncategory:           Development\nbuild-type:         Simple\ndata-files:\n  html/profile.html\n  html/shake.js\n\nextra-source-files: README.md\n\nflag pedantic\n  description: Enable -Werror\n  default:     False\n  manual:      True\n\nflag embed-files\n  default:     False\n  manual:      True\n  description: Embed data files into the shake library\n\nflag stm-stats\n  default:     False\n  manual:      True\n  description: Collect STM transaction stats\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/haskell-language-server\n\ncommon warnings\n  ghc-options:\n    -Wall\n    -Wredundant-constraints\n    -Wunused-packages\n    -Wno-name-shadowing\n    -Wno-unticked-promoted-constructors\n\nlibrary\n  import: warnings\n  exposed-modules:\n    Control.Concurrent.STM.Stats\n    Development.IDE.Graph\n    Development.IDE.Graph.Classes\n    Development.IDE.Graph.Database\n    Development.IDE.Graph.Internal.Action\n    Development.IDE.Graph.Internal.Database\n    Development.IDE.Graph.Internal.Options\n    Development.IDE.Graph.Internal.Key\n    Development.IDE.Graph.Internal.Paths\n    Development.IDE.Graph.Internal.Profile\n    Development.IDE.Graph.Internal.Rules\n    Development.IDE.Graph.Internal.Types\n    Development.IDE.Graph.KeyMap\n    Development.IDE.Graph.KeySet\n    Development.IDE.Graph.Rule\n    Paths_hls_graph\n\n  autogen-modules:    Paths_hls_graph\n  hs-source-dirs:     src\n  build-depends:\n    , aeson\n    , async                 >=2.0\n    , base                  >=4.12    && <5\n    , bytestring\n    , containers\n    , deepseq\n    , exceptions\n    , extra\n    , filepath\n    , focus                 >=1.0.3.2\n    , hashable\n    , js-dgtable\n    , js-flot\n    , js-jquery\n    , list-t\n    , stm\n    , stm-containers\n    , text\n    , time\n    , transformers\n    , unliftio\n    , unordered-containers\n\n  if flag(embed-files)\n    cpp-options:   -DFILE_EMBED\n    build-depends:\n      , file-embed        >=0.0.11\n      , template-haskell\n  else\n    build-depends:\n      directory\n\n  if flag(stm-stats)\n    cpp-options: -DSTM_STATS\n\n  if flag(pedantic)\n    ghc-options: -Werror\n\n  default-language:   GHC2021\n  default-extensions:\n    DataKinds\n\ntest-suite tests\n  import: warnings\n  type:               exitcode-stdio-1.0\n  default-language:   GHC2021\n  hs-source-dirs:     test\n  main-is:            Main.hs\n  other-modules:\n    ActionSpec\n    DatabaseSpec\n    Example\n    RulesSpec\n    Spec\n\n  ghc-options:\n    -threaded -rtsopts -with-rtsopts=-N -fno-ignore-asserts\n\n  build-depends:\n    , base\n    , extra\n    , hls-graph\n    , hspec\n    , stm\n    , stm-containers\n    , tasty\n    , tasty-hspec >= 1.2\n    , tasty-rerun\n\n  build-tool-depends: hspec-discover:hspec-discover\n";
  }