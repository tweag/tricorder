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
    flags = { dev = false; };
    package = {
      specVersion = "2.4";
      identifier = { name = "fourmolu"; version = "0.20.1.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Matt Parsons <parsonsmatt@gmail.com>\nGeorge Thomas <georgefsthomas@gmail.com>\nBrandon Chinn <brandonchinn178@gmail.com>";
      author = "";
      homepage = "https://github.com/fourmolu/fourmolu";
      url = "";
      synopsis = "A formatter for Haskell source code";
      description = "A formatter for Haskell source code.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
          (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
          (hsPkgs."MemoTrie" or (errorHandler.buildDepError "MemoTrie"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."choice" or (errorHandler.buildDepError "choice"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."file-embed" or (errorHandler.buildDepError "file-embed"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
          (hsPkgs."megaparsec" or (errorHandler.buildDepError "megaparsec"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
        ];
        buildable = true;
      };
      exes = {
        "fourmolu" = {
          depends = [
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."th-env" or (errorHandler.buildDepError "th-env"))
            (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."fourmolu" or (errorHandler.buildDepError "fourmolu"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."terminal-size" or (errorHandler.buildDepError "terminal-size"))
            (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
          ];
          buildable = true;
        };
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."choice" or (errorHandler.buildDepError "choice"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-megaparsec" or (errorHandler.buildDepError "hspec-megaparsec"))
            (hsPkgs."megaparsec" or (errorHandler.buildDepError "megaparsec"))
            (hsPkgs."path" or (errorHandler.buildDepError "path"))
            (hsPkgs."path-io" or (errorHandler.buildDepError "path-io"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."fourmolu" or (errorHandler.buildDepError "fourmolu"))
            (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
            (hsPkgs.pkgsBuildBuild.fourmolu.components.exes.fourmolu or (pkgs.pkgsBuildBuild.fourmolu or (errorHandler.buildToolDepError "fourmolu:fourmolu")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/fourmolu-0.20.1.0.tar.gz";
      sha256 = "345e420b6871852b6148caa26a23991f7646786377276716dd36ae5a6cd842c9";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\r\nname: fourmolu\r\nversion: 0.20.1.0\r\nx-revision: 1\r\nlicense: BSD-3-Clause\r\nlicense-file: LICENSE.md\r\nmaintainer:\r\n    Matt Parsons <parsonsmatt@gmail.com>\r\n    George Thomas <georgefsthomas@gmail.com>\r\n    Brandon Chinn <brandonchinn178@gmail.com>\r\ntested-with:\r\n  ghc ==9.10.2\r\n  ghc ==9.12.2\r\n  ghc ==9.14.1\r\n\r\nhomepage: https://github.com/fourmolu/fourmolu\r\nbug-reports: https://github.com/fourmolu/fourmolu/issues\r\nsynopsis: A formatter for Haskell source code\r\ndescription: A formatter for Haskell source code.\r\ncategory: Development, Formatting\r\nbuild-type: Simple\r\nextra-source-files:\r\n  data/**/*.cabal\r\n  data/**/*.hs\r\n  data/**/*.txt\r\n  extract-hackage-info/hackage-info.bin\r\n  -- needed for integration tests\r\n  fixity-tests/*.hs\r\n  region-tests/*.hs\r\n  fourmolu.yaml\r\n\r\nextra-doc-files:\r\n  CHANGELOG.md\r\n  README.md\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/fourmolu/fourmolu.git\r\n\r\nflag dev\r\n  description: Turn on development settings.\r\n  default: False\r\n  manual: True\r\n\r\nlibrary\r\n  exposed-modules:\r\n    Ormolu\r\n    Ormolu.Config\r\n    Ormolu.Diff.ParseResult\r\n    Ormolu.Diff.Text\r\n    Ormolu.Exception\r\n    Ormolu.Fixity\r\n    Ormolu.Fixity.Imports\r\n    Ormolu.Fixity.Internal\r\n    Ormolu.Fixity.Parser\r\n    Ormolu.Fixity.Printer\r\n    Ormolu.Imports\r\n    Ormolu.Parser\r\n    Ormolu.Parser.CommentStream\r\n    Ormolu.Parser.Pragma\r\n    Ormolu.Parser.Result\r\n    Ormolu.Printer\r\n    Ormolu.Printer.Combinators\r\n    Ormolu.Printer.Comments\r\n    Ormolu.Printer.Internal\r\n    Ormolu.Printer.Meat.Common\r\n    Ormolu.Printer.Meat.Declaration\r\n    Ormolu.Printer.Meat.Declaration.Annotation\r\n    Ormolu.Printer.Meat.Declaration.Class\r\n    Ormolu.Printer.Meat.Declaration.Data\r\n    Ormolu.Printer.Meat.Declaration.Default\r\n    Ormolu.Printer.Meat.Declaration.Foreign\r\n    Ormolu.Printer.Meat.Declaration.Instance\r\n    Ormolu.Printer.Meat.Declaration.OpTree\r\n    Ormolu.Printer.Meat.Declaration.RoleAnnotation\r\n    Ormolu.Printer.Meat.Declaration.Rule\r\n    Ormolu.Printer.Meat.Declaration.Signature\r\n    Ormolu.Printer.Meat.Declaration.Splice\r\n    Ormolu.Printer.Meat.Declaration.StringLiteral\r\n    Ormolu.Printer.Meat.Declaration.Type\r\n    Ormolu.Printer.Meat.Declaration.TypeFamily\r\n    Ormolu.Printer.Meat.Declaration.Value\r\n    Ormolu.Printer.Meat.Declaration.Warning\r\n    Ormolu.Printer.Meat.ImportExport\r\n    Ormolu.Printer.Meat.Module\r\n    Ormolu.Printer.Meat.Pragma\r\n    Ormolu.Printer.Meat.Type\r\n    Ormolu.Printer.Meat.Type.Function\r\n    Ormolu.Printer.Operators\r\n    Ormolu.Printer.SpanStream\r\n    Ormolu.Processing.Common\r\n    Ormolu.Processing.Cpp\r\n    Ormolu.Processing.Preprocess\r\n    Ormolu.Terminal\r\n    Ormolu.Terminal.QualifiedDo\r\n    Ormolu.Utils\r\n    Ormolu.Utils.Cabal\r\n    Ormolu.Utils.Fixity\r\n    Ormolu.Utils.IO\r\n\r\n  hs-source-dirs: src\r\n  other-modules: GHC.DynFlags\r\n  default-language: GHC2021\r\n  build-depends:\r\n    Cabal-syntax >=3.16 && <3.17,\r\n    Diff >=0.4 && <2.1,\r\n    MemoTrie >=0.6 && <0.7,\r\n    ansi-terminal >=0.10 && <1.2,\r\n    array >=0.5 && <0.6,\r\n    base >=4.14 && <5,\r\n    binary >=0.8 && <0.9,\r\n    bytestring >=0.2 && <0.13,\r\n    choice >=0.2.4.1 && <0.3,\r\n    containers >=0.5 && <0.9,\r\n    directory ^>=1.3,\r\n    file-embed >=0.0.15 && <0.1,\r\n    filepath >=1.2 && <1.6,\r\n    ghc-lib-parser >=9.14 && <9.15,\r\n    megaparsec >=9,\r\n    mtl >=2 && <3,\r\n    syb >=0.7 && <0.8,\r\n    text >=2.1 && <3,\r\n\r\n  -- specific to fourmolu\r\n  exposed-modules:\r\n    Ormolu.Imports.Grouping\r\n    Ormolu.Utils.Glob\r\n    Paths_fourmolu\r\n  other-modules:\r\n    Ormolu.Config.Gen\r\n    Ormolu.Config.Types\r\n  autogen-modules:\r\n    Paths_fourmolu\r\n  build-depends:\r\n    aeson >=1.0 && <3.0,\r\n    scientific >=0.3.2 && <1,\r\n\r\n  if flag(dev)\r\n    ghc-options:\r\n      -Wall\r\n      -Werror\r\n      -Wredundant-constraints\r\n      -Wpartial-fields\r\n      -Wunused-packages\r\n  else\r\n    ghc-options:\r\n      -O2\r\n      -Wall\r\n\r\nexecutable fourmolu\r\n  main-is: Main.hs\r\n  hs-source-dirs: app\r\n  other-modules: Paths_fourmolu\r\n  autogen-modules: Paths_fourmolu\r\n  default-language: GHC2021\r\n  build-depends:\r\n    Cabal-syntax >=3.16 && <3.17,\r\n    base >=4.12 && <5,\r\n    containers >=0.5 && <0.9,\r\n    directory ^>=1.3,\r\n    filepath >=1.2 && <1.6,\r\n    ghc-lib-parser >=9.14 && <9.15,\r\n    optparse-applicative >=0.14 && <0.20,\r\n    text >=2.1 && <3,\r\n    th-env >=0.1.1 && <0.2,\r\n    unliftio >=0.2.10 && <0.3,\r\n\r\n  -- specific to fourmolu\r\n  build-depends:\r\n    directory >=1.3.3 && <1.4,\r\n    fourmolu,\r\n    optparse-applicative >=0.17,\r\n    terminal-size >=0.1 && <0.4,\r\n    yaml >=0.11.6.0 && <1,\r\n\r\n  -- We use parallelism so we need a threaded runtime to get any\r\n  -- benefit.\r\n  ghc-options:\r\n    -threaded\r\n    -rtsopts\r\n    -with-rtsopts=-N\r\n\r\n  if flag(dev)\r\n    ghc-options:\r\n      -Wall\r\n      -Werror\r\n      -Wredundant-constraints\r\n      -Wpartial-fields\r\n      -Wunused-packages\r\n      -Wwarn=unused-packages\r\n  else\r\n    ghc-options:\r\n      -O2\r\n      -Wall\r\n\r\ntest-suite tests\r\n  type: exitcode-stdio-1.0\r\n  main-is: Spec.hs\r\n  build-tool-depends: hspec-discover:hspec-discover >=2 && <3\r\n  hs-source-dirs: tests\r\n  other-modules:\r\n    Ormolu.CabalInfoSpec\r\n    Ormolu.Diff.TextSpec\r\n    Ormolu.Fixity.ParserSpec\r\n    Ormolu.Fixity.PrinterSpec\r\n    Ormolu.FixitySpec\r\n    Ormolu.OpTreeSpec\r\n    Ormolu.Parser.OptionsSpec\r\n    Ormolu.Parser.ParseFailureSpec\r\n    Ormolu.Parser.PragmaSpec\r\n    Ormolu.PrinterSpec\r\n\r\n  default-language: GHC2021\r\n  build-depends:\r\n    Cabal-syntax >=3.16 && <3.17,\r\n    QuickCheck >=2.14,\r\n    base >=4.14 && <5,\r\n    choice >=0.2.4.1 && <0.3,\r\n    containers >=0.5 && <0.9,\r\n    directory ^>=1.3,\r\n    filepath >=1.2 && <1.6,\r\n    ghc-lib-parser >=9.14 && <9.15,\r\n    hspec >=2 && <3,\r\n    hspec-megaparsec >=2.2,\r\n    megaparsec >=9,\r\n    path >=0.6 && <0.10,\r\n    path-io >=1.4.2 && <2,\r\n    temporary ^>=1.3,\r\n    text >=2.1 && <3,\r\n\r\n  -- specific to fourmolu tests\r\n  other-modules:\r\n    Ormolu.Config.PrinterOptsSpec\r\n    Ormolu.ConfigSpec\r\n    Ormolu.Integration.CLIOptionsSpec\r\n    Ormolu.Integration.CLISpec\r\n    Ormolu.Integration.FixitySpec\r\n    Ormolu.Integration.RegionSpec\r\n    Ormolu.Integration.Utils\r\n    Ormolu.Utils.GlobSpec\r\n  build-depends:\r\n    Diff >=1 && <2.1,\r\n    bytestring,\r\n    fourmolu,\r\n    pretty >=1.0 && <2.0,\r\n    process >=1.6 && <2.0,\r\n    yaml,\r\n  build-tool-depends: fourmolu:fourmolu\r\n\r\n  if flag(dev)\r\n    ghc-options:\r\n      -Wall\r\n      -Werror\r\n      -Wredundant-constraints\r\n      -Wpartial-fields\r\n      -Wunused-packages\r\n  else\r\n    ghc-options:\r\n      -O2\r\n      -Wall\r\n";
  }