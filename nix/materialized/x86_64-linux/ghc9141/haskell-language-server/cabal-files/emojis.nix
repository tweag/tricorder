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
      specVersion = "1.10";
      identifier = { name = "emojis"; version = "0.1.5"; };
      license = "BSD-3-Clause";
      copyright = "2019 John MacFarlane";
      maintainer = "jgm@berkeley.edu";
      author = "John MacFarlane";
      homepage = "https://github.com/jgm/emojis#readme";
      url = "";
      synopsis = "Conversion between emoji characters and their names.";
      description = "This package provides functions for converting\nemoji names to emoji characters and vice versa.\n\nHow does it differ from the @emoji@ package?\n\n-   It supports a fuller range of emojis, including all those\nsupported by GitHub\n-   It supports lookup of emoji aliases from emoji\n-   It uses Text rather than String\n-   It has a lighter dependency footprint: in particular, it\ndoes not require aeson\n-   It does not require TemplateHaskell";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
        ];
        buildable = true;
      };
      tests = {
        "emojis-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."emojis" or (errorHandler.buildDepError "emojis"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/emojis-0.1.5.tar.gz";
      sha256 = "377177f4446bee35bf8c1c23678d38606205714987943fe439799b8791017ddc";
    });
  }) // {
    package-description-override = "name:                emojis\nversion:             0.1.5\nsynopsis:            Conversion between emoji characters and their names.\ndescription:         This package provides functions for converting\n                     emoji names to emoji characters and vice versa.\n                     .\n                     How does it differ from the @emoji@ package?\n                     .\n                     -   It supports a fuller range of emojis, including all those\n                         supported by GitHub\n                     -   It supports lookup of emoji aliases from emoji\n                     -   It uses Text rather than String\n                     -   It has a lighter dependency footprint: in particular, it\n                         does not require aeson\n                     -   It does not require TemplateHaskell\nhomepage:            https://github.com/jgm/emojis#readme\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              John MacFarlane\nmaintainer:          jgm@berkeley.edu\ncopyright:           2019 John MacFarlane\ncategory:            Text\nbuild-type:          Simple\nextra-source-files:  emoji.json, src/Text/emojis.inc, README.md, changelog.md\ncabal-version:       >=1.10\n\nlibrary\n  hs-source-dirs:      src\n  exposed-modules:     Text.Emoji\n  other-modules:       Trie\n  build-depends:       base >= 4.13 && < 5,\n                       text,\n                       containers\n  default-language:    Haskell2010\n  ghc-options:         -Wall -fno-warn-unused-do-bind\n\ntest-suite emojis-test\n  type:                exitcode-stdio-1.0\n  hs-source-dirs:      test\n  main-is:             test.hs\n  build-depends:       base >= 4.9 && < 5,\n                       emojis,\n                       text,\n                       HUnit\n  default-language:    Haskell2010\n  ghc-options:         -Wall -fno-warn-unused-do-bind\n\nsource-repository head\n  type:     git\n  location: https://github.com/jgm/emojis\n";
  }