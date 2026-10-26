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
      identifier = { name = "vty"; version = "6.6"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Jonathan Daugherty (cygnus@foobox.com)";
      author = "AUTHORS";
      homepage = "https://github.com/jtdaugherty/vty";
      url = "";
      synopsis = "A simple terminal UI library";
      description = "vty is terminal GUI library in the niche of ncurses. It is intended to\nbe easy to use and to provide good support for common terminal types.\n\nSee the example programs in the @vty-crossplatform@ package examples\non how to use the library.\n\n&#169; 2006-2007 Stefan O'Rear; BSD3 license.\n\n&#169; Corey O'Connor; BSD3 license.\n\n&#169; Jonathan Daugherty; BSD3 license.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
          (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."parsec" or (errorHandler.buildDepError "parsec"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
        ] ++ pkgs.lib.optionals (!(compiler.isGhc && compiler.version.ge "8.0")) [
          (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
          (hsPkgs."fail" or (errorHandler.buildDepError "fail"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/vty-6.6.tar.gz";
      sha256 = "de9a067010e2f73ac0887696f42b85f234c056fda903e5fd31bc9403f64ce19e";
    });
  }) // {
    package-description-override = "name:                vty\nversion:             6.6\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              AUTHORS\nmaintainer:          Jonathan Daugherty (cygnus@foobox.com)\nhomepage:            https://github.com/jtdaugherty/vty\ncategory:            User Interfaces\nsynopsis:            A simple terminal UI library\ndescription:\n  vty is terminal GUI library in the niche of ncurses. It is intended to\n  be easy to use and to provide good support for common terminal types.\n  .\n  See the example programs in the @vty-crossplatform@ package examples\n  on how to use the library.\n  .\n  &#169; 2006-2007 Stefan O'Rear; BSD3 license.\n  .\n  &#169; Corey O'Connor; BSD3 license.\n  .\n  &#169; Jonathan Daugherty; BSD3 license.\ncabal-version:       1.18\nbuild-type:          Simple\nextra-doc-files:     README.md,\n                     AUTHORS,\n                     CHANGELOG.md,\n                     LICENSE\ntested-with:         GHC==8.0.2, GHC==8.2.2, GHC==8.4.3, GHC==8.6.5, GHC==8.8.4, GHC==8.10.7,\n                     GHC==9.0.2, GHC==9.2.8, GHC==9.4.8, GHC==9.6.6, GHC==9.8.4, GHC==9.10.1,\n                     GHC==9.12.1\n\nsource-repository head\n  type: git\n  location: https://github.com/jtdaugherty/vty.git\n\nlibrary\n  default-language:    Haskell2010\n  include-dirs:        cbits\n  hs-source-dirs:      src\n  ghc-options:         -O2 -funbox-strict-fields -Wall -fspec-constr -fspec-constr-count=10\n  ghc-prof-options:    -O2 -funbox-strict-fields -caf-all -Wall -fspec-constr -fspec-constr-count=10\n  build-depends:       base >= 4.8 && < 5,\n                       blaze-builder >= 0.3.3.2 && < 0.5,\n                       bytestring,\n                       deepseq >= 1.1 && < 1.6,\n                       microlens < 0.6,\n                       microlens-mtl,\n                       mtl >= 1.1.1.0 && < 2.4,\n                       stm,\n                       text >= 0.11.3,\n                       utf8-string >= 0.3.1 && < 1.1,\n                       vector >= 0.7,\n                       binary,\n                       parsec,\n                       filepath,\n                       directory\n\n  if !impl(ghc >= 8.0)\n    build-depends:     semigroups >= 0.16,\n                       fail\n\n  exposed-modules:     Graphics.Text.Width\n                       Graphics.Vty\n                       Graphics.Vty.Attributes\n                       Graphics.Vty.Attributes.Color\n                       Graphics.Vty.Attributes.Color240\n                       Graphics.Vty.Config\n                       Graphics.Vty.Debug\n                       Graphics.Vty.DisplayAttributes\n                       Graphics.Vty.Error\n                       Graphics.Vty.Image\n                       Graphics.Vty.Image.Internal\n                       Graphics.Vty.Inline\n                       Graphics.Vty.Input\n                       Graphics.Vty.Input.Events\n                       Graphics.Vty.Output\n                       Graphics.Vty.Output.Mock\n                       Graphics.Vty.Picture\n                       Graphics.Vty.PictureToSpans\n                       Graphics.Vty.Span\n                       Graphics.Vty.UnicodeWidthTable.IO\n                       Graphics.Vty.UnicodeWidthTable.Install\n                       Graphics.Vty.UnicodeWidthTable.Main\n                       Graphics.Vty.UnicodeWidthTable.Query\n                       Graphics.Vty.UnicodeWidthTable.Types\n  c-sources:           cbits/mk_wcwidth.c\n";
  }