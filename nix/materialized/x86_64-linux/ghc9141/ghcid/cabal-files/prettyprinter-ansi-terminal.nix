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
    flags = { text = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "prettyprinter-ansi-terminal"; version = "1.1.4"; };
      license = "BSD-2-Clause";
      copyright = "";
      maintainer = "Simon Jakobi <simon.jakobi@gmail.com>, David Luposchainsky <dluposchainsky at google>";
      author = "David Luposchainsky";
      homepage = "http://github.com/quchen/prettyprinter";
      url = "";
      synopsis = "ANSI terminal backend for the »prettyprinter« package.";
      description = "See README.md";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
        ] ++ pkgs.lib.optional (flags.text) (hsPkgs."text" or (errorHandler.buildDepError "text"));
        buildable = true;
      };
      tests = {
        "doctest" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doctest" or (errorHandler.buildDepError "doctest"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "large-output" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
            (hsPkgs."prettyprinter-ansi-terminal" or (errorHandler.buildDepError "prettyprinter-ansi-terminal"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/prettyprinter-ansi-terminal-1.1.4.tar.gz";
      sha256 = "912cd340d5c2583111e2eaeb9aa03b87551ca2e3dd78bbfd346756b9f1e6c9fe";
    });
  }) // {
    package-description-override = "name:                prettyprinter-ansi-terminal\nversion:             1.1.4\ncabal-version:       >= 1.10\ncategory:            User Interfaces, Text\nsynopsis:            ANSI terminal backend for the »prettyprinter« package.\ndescription:         See README.md\nlicense:             BSD2\nlicense-file:        LICENSE.md\nextra-source-files:  README.md\n                   , misc/version-compatibility-macros.h\n                   , CHANGELOG.md\nauthor:              David Luposchainsky\nmaintainer:          Simon Jakobi <simon.jakobi@gmail.com>, David Luposchainsky <dluposchainsky at google>\nbug-reports:         http://github.com/quchen/prettyprinter/issues\nhomepage:            http://github.com/quchen/prettyprinter\nbuild-type:          Simple\ntested-with:         GHC==9.14.1, GHC==9.12.2, GHC==9.10.3, GHC==9.8.4, GHC==9.6.7, GHC==9.4.8, GHC==9.2.8, GHC==9.0.2, GHC==8.10.7, GHC==8.8.4, GHC==8.6.5, GHC==8.4.4, GHC==8.2.2, GHC==8.0.2\n\nsource-repository head\n  type: git\n  location: https://github.com/quchen/prettyprinter\n\nflag text\n  description: While it's a core value of @prettyprinter@ packages to use @Text@, there are rare\n               circumstances (mostly when @prettyprinter@ arises as a dependency of\n               test suites of packages like @bytestring@ or @text@ themselves) when\n               this is inconvenient. In this case one can disable this flag, so that\n               @prettyprinter-ansi-terminal@ fallbacks to @String@.\n  default:     True\n  manual:      True\n\nlibrary\n    exposed-modules:  Data.Text.Prettyprint.Doc.Render.Terminal\n                    , Data.Text.Prettyprint.Doc.Render.Terminal.Internal\n                    , Prettyprinter.Render.Terminal\n                    , Prettyprinter.Render.Terminal.Internal\n    ghc-options:      -Wall -O2 -Wcompat\n    hs-source-dirs:   src\n    include-dirs:     misc\n    default-language: Haskell2010\n    other-extensions:\n          CPP\n        , OverloadedStrings\n\n\n    build-depends:\n          base          >= 4.9 && < 5\n        , ansi-terminal >= 0.4.0\n        , prettyprinter >= 1.7.0\n    if flag(text)\n        build-depends: text >= 1.2\n    else\n        -- A fake text package, emulating the same API, but backed by String\n        hs-source-dirs: src-text\n        other-modules:\n              Data.Text\n            , Data.Text.IO\n            , Data.Text.Lazy\n            , Data.Text.Lazy.Builder\n\ntest-suite doctest\n    type: exitcode-stdio-1.0\n    hs-source-dirs: test/Doctest\n    main-is: Main.hs\n    build-depends:\n          base    >= 4.9 && < 5\n        , doctest >= 0.9\n    ghc-options: -Wall -threaded -rtsopts -with-rtsopts=-N\n    default-language: Haskell2010\n\nbenchmark large-output\n    build-depends:\n          base >= 4.9 && < 5\n        , base-compat >=0.9.3 && <0.15\n        , containers\n        , deepseq\n        , tasty-bench >= 0.2\n        , prettyprinter\n        , prettyprinter-ansi-terminal\n        , QuickCheck >= 2.8\n        , text\n\n    hs-source-dirs:      bench\n    main-is:             LargeOutput.hs\n    ghc-options:         -O2 -rtsopts -Wall\n    default-language:    Haskell2010\n    type:                exitcode-stdio-1.0\n";
  }