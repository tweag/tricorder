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
    flags = { demo = false; };
    package = {
      specVersion = "2.2";
      identifier = { name = "lsp"; version = "2.8.0.0"; };
      license = "MIT";
      copyright = "Alan Zimmerman, 2016-2021";
      maintainer = "alan.zimm@gmail.com";
      author = "Alan Zimmerman";
      homepage = "https://github.com/haskell/lsp";
      url = "";
      synopsis = "Haskell library for the Microsoft Language Server Protocol";
      description = "An implementation of the types, and basic message server to\nallow language implementors to support the Language Server\nProtocol for their specific language.\n\nAn example of this is for Haskell via the Haskell Language\nServer, at https://github.com/haskell/haskell-language-server";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."co-log-core" or (errorHandler.buildDepError "co-log-core"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
          (hsPkgs."lens-aeson" or (errorHandler.buildDepError "lens-aeson"))
          (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
          (hsPkgs."sorted-list" or (errorHandler.buildDepError "sorted-list"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."websockets" or (errorHandler.buildDepError "websockets"))
        ];
        buildable = true;
      };
      exes = {
        "lsp-demo-reactor-server" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."co-log-core" or (errorHandler.buildDepError "co-log-core"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.demo then false else true;
        };
        "lsp-demo-simple-server" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.demo then false else true;
        };
      };
      tests = {
        "lsp-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."sorted-list" or (errorHandler.buildDepError "sorted-list"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
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
      url = "http://hackage.haskell.org/package/lsp-2.8.0.0.tar.gz";
      sha256 = "d740f7aa36b95738da98f26e899d4ad491b94cfa977dbcc7b4b1097610ecb420";
    });
  }) // {
    package-description-override = "cabal-version:      2.2\nname:               lsp\nversion:            2.8.0.0\nsynopsis:           Haskell library for the Microsoft Language Server Protocol\ndescription:\n  An implementation of the types, and basic message server to\n  allow language implementors to support the Language Server\n  Protocol for their specific language.\n  .\n  An example of this is for Haskell via the Haskell Language\n  Server, at https://github.com/haskell/haskell-language-server\n\nhomepage:           https://github.com/haskell/lsp\nlicense:            MIT\nlicense-file:       LICENSE\nauthor:             Alan Zimmerman\nmaintainer:         alan.zimm@gmail.com\ncopyright:          Alan Zimmerman, 2016-2021\ncategory:           Development\nbuild-type:         Simple\nextra-doc-files:\n  ChangeLog.md\n  README.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/lsp\n\ncommon warnings\n  ghc-options: -Wall -Wunused-packages -Wno-unticked-promoted-constructors\n\nlibrary\n  import: warnings\n  hs-source-dirs:     src\n  default-language:   GHC2021\n  ghc-options:        -fprint-explicit-kinds\n  reexported-modules:\n    , Language.LSP.Protocol.Types\n    , Language.LSP.Protocol.Lens\n    , Language.LSP.Protocol.Capabilities\n    , Language.LSP.Protocol.Message\n\n  exposed-modules:\n    Language.LSP.Diagnostics\n    Language.LSP.Logging\n    Language.LSP.Server\n    Language.LSP.VFS\n\n  other-modules:\n    Language.LSP.Server.Control\n    Language.LSP.Server.Core\n    Language.LSP.Server.Processing\n    Language.LSP.Server.Progress\n\n  build-depends:\n    , aeson                 >=2      && <2.3\n    , async                 ^>=2.2\n    , attoparsec            ^>=0.14\n    , base                  >=4.11   && <5\n    , bytestring            >=0.10   && <0.13\n    , co-log-core           ^>=0.3\n    , containers            >=0.6 && < 0.9\n    , data-default          >=0.7 && < 0.9\n    , directory             ^>=1.3\n    , exceptions            ^>=0.10\n    , extra                 >=1.7 && < 1.9\n    , filepath              >=1.4 && < 1.6\n    , hashable              >=1.4 && < 1.6\n    , lens                  >=5.1    && <5.4\n    , lens-aeson            ^>=1.2\n    , lsp-types             ^>=2.4\n    , mtl                   >=2.2    && <2.4\n    , prettyprinter         ^>=1.7\n    , sorted-list           >=0.2.1 && < 0.4\n    , stm                   ^>=2.5\n    , text                  >=1      && <2.2\n    , text-rope             >=0.2    && <0.4\n    , transformers          >=0.5    && <0.7\n    , unliftio              ^>=0.2\n    , unliftio-core         ^>=0.2\n    , unordered-containers  ^>=0.2\n    , websockets            ^>=0.13\n\nexecutable lsp-demo-reactor-server\n  import:             warnings\n  main-is:            Reactor.hs\n  hs-source-dirs:     example\n  default-language:   GHC2021\n  build-depends:\n    , aeson\n    , base\n    , co-log-core\n    , lens\n    , lsp\n    , prettyprinter\n    , stm\n    , text\n\n  -- the package library. Comment this out if you want repl changes to propagate\n  if !flag(demo)\n    buildable: False\n\nexecutable lsp-demo-simple-server\n  import:             warnings\n  main-is:            Simple.hs\n  hs-source-dirs:     example\n  default-language:   GHC2021\n  build-depends:\n    , base\n    , lsp\n    , text\n\n  -- the package library. Comment this out if you want repl changes to propagate\n  if !flag(demo)\n    buildable: False\n\nflag demo\n  description: Build the demo executables\n  default:     False\n\ntest-suite lsp-test\n  import:             warnings\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     test\n  main-is:            Main.hs\n  other-modules:\n    DiagnosticsSpec\n    Spec\n    VspSpec\n\n  build-depends:\n    , base\n    , containers\n    , hspec\n    , lsp\n    , sorted-list\n    , text\n    , text-rope\n    , unordered-containers\n\n  build-tool-depends: hspec-discover:hspec-discover\n  ghc-options:        -threaded -rtsopts -with-rtsopts=-N\n  default-language:   GHC2021\n";
  }