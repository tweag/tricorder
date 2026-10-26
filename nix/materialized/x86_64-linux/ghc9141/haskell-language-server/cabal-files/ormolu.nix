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
      identifier = { name = "ormolu"; version = "0.8.2.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Mark Karpov <markkarpov92@gmail.com>";
      author = "";
      homepage = "https://github.com/mrkkrp/ormolu";
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
        ];
        buildable = true;
      };
      exes = {
        "ormolu" = {
          depends = [
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."ormolu" or (errorHandler.buildDepError "ormolu"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."th-env" or (errorHandler.buildDepError "th-env"))
            (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
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
            (hsPkgs."ormolu" or (errorHandler.buildDepError "ormolu"))
            (hsPkgs."path" or (errorHandler.buildDepError "path"))
            (hsPkgs."path-io" or (errorHandler.buildDepError "path-io"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
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
      url = "http://hackage.haskell.org/package/ormolu-0.8.2.0.tar.gz";
      sha256 = "9ce1e8a1cefe21c7588b3d7ab3d26f353cf6a63cf68576eee203df144aec04f2";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\nname: ormolu\nversion: 0.8.2.0\nlicense: BSD-3-Clause\nlicense-file: LICENSE.md\nmaintainer: Mark Karpov <markkarpov92@gmail.com>\ntested-with:\n  ghc ==9.10.2\n  ghc ==9.12.2\n  ghc ==9.14.1\n\nhomepage: https://github.com/mrkkrp/ormolu\nbug-reports: https://github.com/mrkkrp/ormolu/issues\nsynopsis: A formatter for Haskell source code\ndescription: A formatter for Haskell source code.\ncategory: Development, Formatting\nbuild-type: Simple\nextra-source-files:\n  data/**/*.cabal\n  data/**/*.hs\n  data/**/*.txt\n  extract-hackage-info/hackage-info.bin\n\nextra-doc-files:\n  CHANGELOG.md\n  CONTRIBUTING.md\n  DESIGN.md\n  README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/mrkkrp/ormolu.git\n\nflag dev\n  description: Turn on development settings.\n  default: False\n  manual: True\n\nlibrary\n  exposed-modules:\n    Ormolu\n    Ormolu.Config\n    Ormolu.Diff.ParseResult\n    Ormolu.Diff.Text\n    Ormolu.Exception\n    Ormolu.Fixity\n    Ormolu.Fixity.Imports\n    Ormolu.Fixity.Internal\n    Ormolu.Fixity.Parser\n    Ormolu.Fixity.Printer\n    Ormolu.Imports\n    Ormolu.Parser\n    Ormolu.Parser.CommentStream\n    Ormolu.Parser.Pragma\n    Ormolu.Parser.Result\n    Ormolu.Printer\n    Ormolu.Printer.Combinators\n    Ormolu.Printer.Comments\n    Ormolu.Printer.Internal\n    Ormolu.Printer.Meat.Common\n    Ormolu.Printer.Meat.Declaration\n    Ormolu.Printer.Meat.Declaration.Annotation\n    Ormolu.Printer.Meat.Declaration.Class\n    Ormolu.Printer.Meat.Declaration.Data\n    Ormolu.Printer.Meat.Declaration.Default\n    Ormolu.Printer.Meat.Declaration.Foreign\n    Ormolu.Printer.Meat.Declaration.Instance\n    Ormolu.Printer.Meat.Declaration.OpTree\n    Ormolu.Printer.Meat.Declaration.RoleAnnotation\n    Ormolu.Printer.Meat.Declaration.Rule\n    Ormolu.Printer.Meat.Declaration.Signature\n    Ormolu.Printer.Meat.Declaration.Splice\n    Ormolu.Printer.Meat.Declaration.StringLiteral\n    Ormolu.Printer.Meat.Declaration.Type\n    Ormolu.Printer.Meat.Declaration.TypeFamily\n    Ormolu.Printer.Meat.Declaration.Value\n    Ormolu.Printer.Meat.Declaration.Warning\n    Ormolu.Printer.Meat.ImportExport\n    Ormolu.Printer.Meat.Module\n    Ormolu.Printer.Meat.Pragma\n    Ormolu.Printer.Meat.Type\n    Ormolu.Printer.Operators\n    Ormolu.Printer.SpanStream\n    Ormolu.Processing.Common\n    Ormolu.Processing.Cpp\n    Ormolu.Processing.Preprocess\n    Ormolu.Terminal\n    Ormolu.Terminal.QualifiedDo\n    Ormolu.Utils\n    Ormolu.Utils.Cabal\n    Ormolu.Utils.Fixity\n    Ormolu.Utils.IO\n\n  hs-source-dirs: src\n  other-modules: GHC.DynFlags\n  default-language: GHC2021\n  build-depends:\n    Cabal-syntax >=3.16 && <3.17,\n    Diff >=0.4 && <2,\n    MemoTrie >=0.6 && <0.7,\n    ansi-terminal >=0.10 && <1.2,\n    array >=0.5 && <0.6,\n    base >=4.14 && <5,\n    binary >=0.8 && <0.9,\n    bytestring >=0.2 && <0.13,\n    choice >=0.2.4.1 && <0.3,\n    containers >=0.5 && <0.9,\n    directory ^>=1.3,\n    file-embed >=0.0.15 && <0.1,\n    filepath >=1.2 && <1.6,\n    ghc-lib-parser >=9.14 && <9.15,\n    megaparsec >=9,\n    mtl >=2 && <3,\n    syb >=0.7 && <0.8,\n    text >=2.1 && <3,\n\n  if flag(dev)\n    ghc-options:\n      -Wall\n      -Werror\n      -Wredundant-constraints\n      -Wpartial-fields\n      -Wunused-packages\n  else\n    ghc-options:\n      -O2\n      -Wall\n\nexecutable ormolu\n  main-is: Main.hs\n  hs-source-dirs: app\n  other-modules: Paths_ormolu\n  autogen-modules: Paths_ormolu\n  default-language: GHC2021\n  build-depends:\n    Cabal-syntax >=3.16 && <3.17,\n    base >=4.12 && <5,\n    containers >=0.5 && <0.9,\n    directory ^>=1.3,\n    filepath >=1.2 && <1.6,\n    ghc-lib-parser >=9.14 && <9.15,\n    optparse-applicative >=0.14 && <0.20,\n    ormolu,\n    text >=2.1 && <3,\n    th-env >=0.1.1 && <0.2,\n    unliftio >=0.2.10 && <0.3,\n\n  -- We use parallelism so we need a threaded runtime to get any\n  -- benefit.\n  ghc-options:\n    -threaded\n    -rtsopts\n    -with-rtsopts=-N\n\n  if flag(dev)\n    ghc-options:\n      -Wall\n      -Werror\n      -Wredundant-constraints\n      -Wpartial-fields\n      -Wunused-packages\n      -Wwarn=unused-packages\n  else\n    ghc-options:\n      -O2\n      -Wall\n\ntest-suite tests\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  build-tool-depends: hspec-discover:hspec-discover >=2 && <3\n  hs-source-dirs: tests\n  other-modules:\n    Ormolu.CabalInfoSpec\n    Ormolu.Diff.TextSpec\n    Ormolu.Fixity.ParserSpec\n    Ormolu.Fixity.PrinterSpec\n    Ormolu.FixitySpec\n    Ormolu.OpTreeSpec\n    Ormolu.Parser.OptionsSpec\n    Ormolu.Parser.ParseFailureSpec\n    Ormolu.Parser.PragmaSpec\n    Ormolu.PrinterSpec\n\n  default-language: GHC2021\n  build-depends:\n    Cabal-syntax >=3.16 && <3.17,\n    QuickCheck >=2.14,\n    base >=4.14 && <5,\n    choice >=0.2.4.1 && <0.3,\n    containers >=0.5 && <0.9,\n    directory ^>=1.3,\n    filepath >=1.2 && <1.6,\n    ghc-lib-parser >=9.14 && <9.15,\n    hspec >=2 && <3,\n    hspec-megaparsec >=2.2,\n    megaparsec >=9,\n    ormolu,\n    path >=0.6 && <0.10,\n    path-io >=1.4.2 && <2,\n    temporary ^>=1.3,\n    text >=2.1 && <3,\n\n  if flag(dev)\n    ghc-options:\n      -Wall\n      -Werror\n      -Wredundant-constraints\n      -Wpartial-fields\n      -Wunused-packages\n  else\n    ghc-options:\n      -O2\n      -Wall\n";
  }