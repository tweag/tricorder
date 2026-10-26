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
      specVersion = "1.18";
      identifier = { name = "polyparse"; version = "1.13.1"; };
      license = "LicenseRef-LGPL";
      copyright = "(c) 2006-2016 Malcolm Wallace";
      maintainer = "Andreas Abel";
      author = "Malcolm Wallace <Malcolm.Wallace@me.com>";
      homepage = "";
      url = "";
      synopsis = "A variety of alternative parser combinator libraries.";
      description = "A variety of alternative parser combinator libraries, including\nthe original HuttonMeijer set.  The Poly sets have features like\ngood error reporting, arbitrary token type, running state, lazy\nparsing, and so on.  Finally, Text.Parse is a proposed\nreplacement for the standard Read class, for better\ndeserialisation of Haskell values from Strings.\n\nOld homepage: <https://archives.haskell.org/projects.haskell.org/polyparse/>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ pkgs.lib.optionals (compiler.isGhc && true) [
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/polyparse-1.13.1.tar.gz";
      sha256 = "395b89ed9901e9b19eaa652d2a17b9d1ed04c111b2cd92b8996868bea642bfd6";
    });
  }) // {
    package-description-override = "cabal-version:  1.18\nname:           polyparse\nversion:        1.13.1\nlicense:        LGPL\nlicense-files:  COPYRIGHT, LICENCE-LGPL, LICENCE-commercial\ncopyright:      (c) 2006-2016 Malcolm Wallace\nauthor:         Malcolm Wallace <Malcolm.Wallace@me.com>\nmaintainer:     Andreas Abel\n-- homepage:\nbug-reports:    https://github.com/haskell-pkg-janitors/polyparse/issues\ncategory:       Text, Parsing\nsynopsis:       A variety of alternative parser combinator libraries.\ndescription:\n        A variety of alternative parser combinator libraries, including\n        the original HuttonMeijer set.  The Poly sets have features like\n        good error reporting, arbitrary token type, running state, lazy\n        parsing, and so on.  Finally, Text.Parse is a proposed\n        replacement for the standard Read class, for better\n        deserialisation of Haskell values from Strings.\n        .\n        Old homepage: <https://archives.haskell.org/projects.haskell.org/polyparse/>\n\nbuild-type:     Simple\n\nextra-doc-files:\n  Changelog.md\n  README.md\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.2\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nsource-repository head\n  type:      git\n  location:  https://github.com/haskell-pkg-janitors/polyparse.git\n\nlibrary\n  hs-source-dirs:       src\n\n  exposed-modules:\n        Text.ParserCombinators.HuttonMeijer\n        Text.ParserCombinators.HuttonMeijerWallace\n        Text.ParserCombinators.Poly\n        Text.ParserCombinators.Poly.Base\n        Text.ParserCombinators.Poly.Result\n        Text.ParserCombinators.Poly.Parser\n        Text.ParserCombinators.Poly.Plain\n        Text.ParserCombinators.Poly.Lazy\n        Text.ParserCombinators.Poly.StateParser\n        Text.ParserCombinators.Poly.State\n        Text.ParserCombinators.Poly.StateLazy\n        Text.ParserCombinators.Poly.Lex\n        Text.Parse\n\n  build-depends:        base       >= 4.9     && < 5\n\n  if impl(ghc)\n    build-depends:      bytestring >= 0.9.1.0 && < 0.13\n    build-depends:      text       >= 1.2.3.0 && < 1.3 || >= 2.0 && < 3\n    exposed-modules:\n        Text.ParserCombinators.Poly.ByteString\n        Text.ParserCombinators.Poly.ByteStringChar\n        Text.Parse.ByteString\n        Text.ParserCombinators.Poly.Text\n        Text.ParserCombinators.Poly.StateText\n\n  default-language:     Haskell2010\n  default-extensions:   CPP\n";
  }