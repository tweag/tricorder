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
    flags = { pedantic = false; executable = true; };
    package = {
      specVersion = "3.4";
      identifier = { name = "ghcide"; version = "2.15.0.0"; };
      license = "Apache-2.0";
      copyright = "Digital Asset and Ghcide contributors 2018-2020";
      maintainer = "Ghcide contributors";
      author = "Digital Asset and Ghcide contributors";
      homepage = "https://github.com/haskell/haskell-language-server/tree/master/ghcide#readme";
      url = "";
      synopsis = "The core of an IDE";
      description = "A library for building Haskell IDE's on top of the GHC API.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."co-log-core" or (errorHandler.buildDepError "co-log-core"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."cryptohash-sha1" or (errorHandler.buildDepError "cryptohash-sha1"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."dependent-map" or (errorHandler.buildDepError "dependent-map"))
          (hsPkgs."dependent-sum" or (errorHandler.buildDepError "dependent-sum"))
          (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
          (hsPkgs."edit-distance" or (errorHandler.buildDepError "edit-distance"))
          (hsPkgs."enummapset" or (errorHandler.buildDepError "enummapset"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."fingertree" or (errorHandler.buildDepError "fingertree"))
          (hsPkgs."focus" or (errorHandler.buildDepError "focus"))
          (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
          (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
          (hsPkgs."ghc-trace-events" or (errorHandler.buildDepError "ghc-trace-events"))
          (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
          (hsPkgs."haddock-library" or (errorHandler.buildDepError "haddock-library"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."hie-bios" or (errorHandler.buildDepError "hie-bios"))
          (hsPkgs."hiedb" or (errorHandler.buildDepError "hiedb"))
          (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
          (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
          (hsPkgs."implicit-hie" or (errorHandler.buildDepError "implicit-hie"))
          (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
          (hsPkgs."lens-aeson" or (errorHandler.buildDepError "lens-aeson"))
          (hsPkgs."list-t" or (errorHandler.buildDepError "list-t"))
          (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
          (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."opentelemetry" or (errorHandler.buildDepError "opentelemetry"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."parallel" or (errorHandler.buildDepError "parallel"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
          (hsPkgs."prettyprinter-ansi-terminal" or (errorHandler.buildDepError "prettyprinter-ansi-terminal"))
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
          (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
          (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
          (hsPkgs."sorted-list" or (errorHandler.buildDepError "sorted-list"))
          (hsPkgs."sqlite-simple" or (errorHandler.buildDepError "sqlite-simple"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
          (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ] ++ (if system.isWindows
          then [ (hsPkgs."Win32" or (errorHandler.buildDepError "Win32")) ]
          else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
        buildable = true;
      };
      exes = {
        "ghcide" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."gitrev" or (errorHandler.buildDepError "gitrev"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          ];
          buildable = if !flags.executable then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/ghcide-2.15.0.0.tar.gz";
      sha256 = "3ce5d8bb9d1e5e916fba7671b4c88853d7f460427349a819035a10e20eaab8c3";
    });
  }) // {
    package-description-override = "cabal-version:      3.4\nbuild-type:         Simple\ncategory:           Development\nname:               ghcide\nversion:            2.15.0.0\nlicense:            Apache-2.0\nlicense-file:       LICENSE\nauthor:             Digital Asset and Ghcide contributors\nmaintainer:         Ghcide contributors\ncopyright:          Digital Asset and Ghcide contributors 2018-2020\nsynopsis:           The core of an IDE\ndescription:        A library for building Haskell IDE's on top of the GHC API.\nhomepage:\n  https://github.com/haskell/haskell-language-server/tree/master/ghcide#readme\n\nbug-reports:        https://github.com/haskell/haskell-language-server/issues\ntested-with:        GHC == {9.14.1, 9.12.2, 9.10.3, 9.8.4, 9.6.7}\nextra-source-files:\n  CHANGELOG.md\n  README.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/haskell-language-server.git\n\nflag pedantic\n  description: Enable -Werror\n  default:     False\n  manual:      True\n\ncommon warnings\n  ghc-options:\n    -Werror=incomplete-patterns\n    -Wall\n    -Wincomplete-uni-patterns\n    -Wunused-packages\n    -Wno-name-shadowing\n    -Wno-unticked-promoted-constructors\n    -fno-ignore-asserts\n\nlibrary\n  import: warnings\n  default-language:   GHC2021\n  build-depends:\n    , aeson\n    , array\n    , async\n    , base                         >=4.16     && <5\n    , base16-bytestring            >=0.1.1    && <1.1\n    , binary\n    , bytestring\n    , case-insensitive\n    , co-log-core\n    , containers\n    , cryptohash-sha1              >=0.11.100 && <0.12\n    , data-default\n    , deepseq\n    , dependent-map\n    , dependent-sum\n    , Diff                         ^>=0.5 || ^>=1.0.0\n    , directory\n    , dlist\n    , edit-distance\n    , enummapset\n    , exceptions\n    , extra                        >=1.8\n    , filepath\n    , fingertree\n    , focus                        >=1.0.3.2\n    , ghc                          >=9.2\n    , ghc-boot\n    , ghc-boot-th\n    , ghc-trace-events\n    , Glob\n    , haddock-library              >=1.8      && <1.12\n    , hashable\n    , hie-bios                     ^>= 0.21.0\n    , hiedb                        ^>= 0.8.0.0\n    , hls-graph                    == 2.15.0.0\n    , hls-plugin-api               == 2.15.0.0\n    , implicit-hie                 >= 0.1.4.0 && < 0.1.5\n    , lens\n    , lens-aeson\n    , list-t\n    , lsp                          ^>=2.8\n    , lsp-types                    ^>=2.4\n    , mtl\n    , opentelemetry                >=0.6.1\n    , optparse-applicative\n    , parallel\n    , process\n    , prettyprinter                >=1.7\n    , prettyprinter-ansi-terminal\n    , random\n    , regex-tdfa                   >=1.3.1.0\n    , safe-exceptions\n    , sorted-list\n    , sqlite-simple\n    , stm\n    , stm-containers\n    , syb\n    , text\n    , text-rope\n    , time\n    , transformers\n    , unliftio                     >=0.2.6\n    , unliftio-core\n    , unordered-containers         >=0.2.21\n    , vector\n\n  if os(windows)\n    build-depends: Win32\n\n  else\n    build-depends: unix\n\n  default-extensions:\n    DataKinds\n    ExplicitNamespaces\n    LambdaCase\n    OverloadedStrings\n    RecordWildCards\n    ViewPatterns\n\n  hs-source-dirs:     src session-loader\n  exposed-modules:\n    Control.Concurrent.Strict\n    Development.IDE\n    Development.IDE.Core.Actions\n    Development.IDE.Core.Compile\n    Development.IDE.Core.Debouncer\n    Development.IDE.Core.FileStore\n    Development.IDE.Core.FileUtils\n    Development.IDE.Core.IdeConfiguration\n    Development.IDE.Core.LookupMod\n    Development.IDE.Core.OfInterest\n    Development.IDE.Core.PluginUtils\n    Development.IDE.Core.PositionMapping\n    Development.IDE.Core.Preprocessor\n    Development.IDE.Core.ProgressReporting\n    Development.IDE.Core.Rules\n    Development.IDE.Core.RuleTypes\n    Development.IDE.Core.Service\n    Development.IDE.Core.Shake\n    Development.IDE.Core.Text\n    Development.IDE.Core.Tracing\n    Development.IDE.Core.UseStale\n    Development.IDE.Core.WorkerThread\n    Development.IDE.GHC.Compat\n    Development.IDE.GHC.Compat.Core\n    Development.IDE.GHC.Compat.CmdLine\n    Development.IDE.GHC.Compat.Driver\n    Development.IDE.GHC.Compat.Env\n    Development.IDE.GHC.Compat.Error\n    Development.IDE.GHC.Compat.Iface\n    Development.IDE.GHC.Compat.Logger\n    Development.IDE.GHC.Compat.Outputable\n    Development.IDE.GHC.Compat.Parser\n    Development.IDE.GHC.Compat.Plugins\n    Development.IDE.GHC.Compat.Units\n    Development.IDE.GHC.Compat.Util\n    Development.IDE.GHC.CoreFile\n    Development.IDE.GHC.Error\n    Development.IDE.GHC.Orphans\n    Development.IDE.GHC.Util\n    Development.IDE.Import.DependencyInformation\n    Development.IDE.Import.FindImports\n    Development.IDE.LSP.HoverDefinition\n    Development.IDE.LSP.LanguageServer\n    Development.IDE.LSP.Notifications\n    Development.IDE.LSP.Outline\n    Development.IDE.LSP.Server\n    Development.IDE.Main\n    Development.IDE.Main.HeapStats\n    Development.IDE.Monitoring.OpenTelemetry\n    Development.IDE.Plugin\n    Development.IDE.Plugin.Completions\n    Development.IDE.Plugin.Completions.Types\n    Development.IDE.Plugin.Completions.Logic\n    Development.IDE.Plugin.HLS\n    Development.IDE.Plugin.HLS.GhcIde\n    Development.IDE.Plugin.Test\n    Development.IDE.Plugin.TypeLenses\n    Development.IDE.Session\n    Development.IDE.Session.Dependency\n    Development.IDE.Session.Diagnostics\n    Development.IDE.Session.Ghc\n    Development.IDE.Session.Implicit\n    Development.IDE.Spans.AtPoint\n    Development.IDE.Spans.Common\n    Development.IDE.Spans.Documentation\n    Development.IDE.Spans.LocalBindings\n    Development.IDE.Spans.Pragmas\n    Development.IDE.Types.Diagnostics\n    Development.IDE.Types.Exports\n    Development.IDE.Types.HscEnvEq\n    Development.IDE.Types.KnownTargets\n    Development.IDE.Types.Location\n    Development.IDE.Types.Monitoring\n    Development.IDE.Types.Options\n    Development.IDE.Types.Shake\n    Generics.SYB.GHC\n    Text.Fuzzy.Parallel\n    Text.Fuzzy.Levenshtein\n\n  other-modules:\n    Development.IDE.Core.FileExists\n    Development.IDE.GHC.CPP\n    Development.IDE.GHC.Warnings\n    Development.IDE.Types.Action\n    Development.IDE.Session.OrderedSet\n\n  if flag(pedantic)\n    ghc-options:\n      -Werror\n\nflag executable\n  description: Build the ghcide executable\n  default:     True\n\nexecutable ghcide\n  import: warnings\n  default-language:   GHC2021\n  hs-source-dirs:     exe\n  ghc-options:        -threaded -rtsopts \"-with-rtsopts=-I0 -A128M -T\"\n\n\n  -- allow user RTS overrides\n  -- disable idle GC\n  -- increase nursery size\n  -- Enable collection of heap statistics\n  main-is:            Main.hs\n  build-depends:\n    , base                  >=4.16 && <5\n    , data-default\n    , extra\n    , ghcide\n    , gitrev\n    , hls-plugin-api\n    , lsp\n    , lsp-types\n    , optparse-applicative\n\n  other-modules:\n    Arguments\n    Paths_ghcide\n\n  autogen-modules:    Paths_ghcide\n  default-extensions:\n    LambdaCase\n    OverloadedStrings\n    RecordWildCards\n    ViewPatterns\n\n  if !flag(executable)\n    buildable: False\n";
  }