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
      identifier = { name = "lsp-test"; version = "0.18.0.0"; };
      license = "BSD-3-Clause";
      copyright = "2021 Luke Lau";
      maintainer = "luke_lau@icloud.com";
      author = "Luke Lau";
      homepage = "https://github.com/haskell/lsp/blob/master/lsp-test/README.md";
      url = "";
      synopsis = "Functional test framework for LSP servers.";
      description = "A test framework for writing tests against\n<https://microsoft.github.io/language-server-protocol/ Language Server Protocol servers>.\n@Language.LSP.Test@ launches your server as a subprocess and allows you to simulate a session\ndown to the wire.\nTo see examples of it in action, check out <https://github.com/haskell/haskell-ide-engine haskell-ide-engine>,\n<https://github.com/haskell/haskell-language-server haskell-language-server> and\n<https://github.com/digital-asset/ghcide ghcide>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."co-log-core" or (errorHandler.buildDepError "co-log-core"))
          (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
          (hsPkgs."conduit-parse" or (errorHandler.buildDepError "conduit-parse"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
          (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
          (hsPkgs."lens-aeson" or (errorHandler.buildDepError "lens-aeson"))
          (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
          (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."parser-combinators" or (errorHandler.buildDepError "parser-combinators"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."some" or (errorHandler.buildDepError "some"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ] ++ (if system.isWindows
          then [ (hsPkgs."Win32" or (errorHandler.buildDepError "Win32")) ]
          else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."parser-combinators" or (errorHandler.buildDepError "parser-combinators"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
          ];
          buildable = true;
        };
        "func-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."co-log-core" or (errorHandler.buildDepError "co-log-core"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."parser-combinators" or (errorHandler.buildDepError "parser-combinators"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
          ];
          buildable = true;
        };
        "example" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."parser-combinators" or (errorHandler.buildDepError "parser-combinators"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.lsp.components.exes.lsp-demo-reactor-server or (pkgs.pkgsBuildBuild.lsp-demo-reactor-server or (errorHandler.buildToolDepError "lsp:lsp-demo-reactor-server")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "simple-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/lsp-test-0.18.0.0.tar.gz";
      sha256 = "03ae4cacdd60616e5eba2a02abb91e2192c134ff0cbeee889edc268ddc92d091";
    });
  }) // {
    package-description-override = "cabal-version:      2.4\nname:               lsp-test\nversion:            0.18.0.0\nsynopsis:           Functional test framework for LSP servers.\ndescription:\n  A test framework for writing tests against\n  <https://microsoft.github.io/language-server-protocol/ Language Server Protocol servers>.\n  @Language.LSP.Test@ launches your server as a subprocess and allows you to simulate a session\n  down to the wire.\n  To see examples of it in action, check out <https://github.com/haskell/haskell-ide-engine haskell-ide-engine>,\n  <https://github.com/haskell/haskell-language-server haskell-language-server> and\n  <https://github.com/digital-asset/ghcide ghcide>.\n\nhomepage:\n  https://github.com/haskell/lsp/blob/master/lsp-test/README.md\n\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Luke Lau\nmaintainer:         luke_lau@icloud.com\nbug-reports:        https://github.com/haskell/lsp/issues\ncopyright:          2021 Luke Lau\ncategory:           Testing\nbuild-type:         Simple\nextra-doc-files:\n  ChangeLog.md\n  README.md\nextra-source-files:\n  test/data/**/*.hs\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/lsp\n\ncommon warnings\n  ghc-options: -Wunused-packages\n\nlibrary\n  import:             warnings\n  hs-source-dirs:     src\n  default-language:   GHC2021\n  exposed-modules:    Language.LSP.Test\n  reexported-modules:\n    lsp-types:Language.LSP.Protocol.Types\n    , lsp-types:Language.LSP.Protocol.Message\n    , lsp-types:Language.LSP.Protocol.Capabilities\n    , parser-combinators:Control.Applicative.Combinators\n\n  build-depends:\n    , aeson               >=2     && <2.3\n    , aeson-pretty        ^>=0.8\n    , ansi-terminal       >=0.10  && <1.2\n    , async               ^>=2.2\n    , base                >=4.10  && <5\n    , bytestring          >=0.10  && <0.13\n    , co-log-core         ^>=0.3\n    , conduit             ^>=1.3\n    , conduit-parse       ^>=0.2\n    , containers          >=0.6 && < 0.9\n    , data-default        >=0.7 && < 0.9\n    , Diff                >=0.4   && <1.1\n    , directory           ^>=1.3\n    , exceptions          ^>=0.10\n    , extra               >=1.7 && < 1.9\n    , filepath            >=1.4 && < 1.6\n    , Glob                >=0.9   && <0.11\n    , lens                >=5.1   && <5.4\n    , lens-aeson          ^>=1.2\n    , lsp                 ^>=2.8\n    , lsp-types           ^>=2.4\n    , mtl                 >=2.2   && <2.4\n    , parser-combinators  ^>=1.3\n    , process             ^>=1.6\n    , some                ^>=1.0\n    , text                >=1     && <2.2\n    , time                >=1.10  && <1.16\n    , transformers        >=0.5   && <0.7\n\n  if os(windows)\n    build-depends: Win32\n\n  else\n    build-depends: unix\n\n  other-modules:\n    Language.LSP.Test.Compat\n    Language.LSP.Test.Decoding\n    Language.LSP.Test.Exceptions\n    Language.LSP.Test.Files\n    Language.LSP.Test.Parsing\n    Language.LSP.Test.Server\n    Language.LSP.Test.Session\n\n  ghc-options:        -W\n\ntest-suite tests\n  import:             warnings\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     test\n  main-is:            Test.hs\n  default-language:   GHC2021\n  ghc-options:        -W\n  other-modules:      DummyServer\n  build-depends:\n    , aeson\n    , base\n    , containers\n    , data-default\n    , directory\n    , extra\n    , filepath\n    , hspec\n    , lens\n    , lsp\n    , lsp-test\n    , mtl\n    , parser-combinators\n    , process\n    , text\n    , unliftio\n\ntest-suite func-test\n  import:             warnings\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     func-test\n  default-language:   GHC2021\n  main-is:            FuncTest.hs\n  build-depends:\n    , base\n    , aeson\n    , co-log-core\n    , extra\n    , hspec\n    , lens\n    , lsp\n    , lsp-test\n    , parser-combinators\n    , process\n    , unliftio\n\ntest-suite example\n  import:             warnings\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     example\n  default-language:   GHC2021\n  main-is:            Test.hs\n  build-depends:\n    , base\n    , lsp-test\n    , parser-combinators\n\n  build-tool-depends: lsp:lsp-demo-reactor-server\n\nbenchmark simple-bench\n  import:             warnings\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     bench\n  default-language:   GHC2021\n  main-is:            SimpleBench.hs\n  ghc-options:        -Wall -O2 -rtsopts\n  build-depends:\n    , base\n    , extra\n    , lsp\n    , lsp-test\n    , process\n";
  }