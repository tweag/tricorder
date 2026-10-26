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
      identifier = { name = "lucid"; version = "2.11.20260427"; };
      license = "BSD-3-Clause";
      copyright = "2014-2021 Chris Done";
      maintainer = "chrisdone@gmail.com";
      author = "Chris Done";
      homepage = "https://github.com/chrisdone/lucid";
      url = "";
      synopsis = "Clear to write, read and edit DSL for HTML";
      description = "Clear to write, read and edit DSL for HTML.\n\n* Names are consistent, and do not conflict with base or are keywords (all have suffix @_@)\n\n* Same combinator can be used for attributes and elements (e.g. 'style_')\n\n* For more, read <https://chrisdone.com/posts/lucid the blog post>\n\nSee the \"Lucid\" module for more documentation.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."mmorph" or (errorHandler.buildDepError "mmorph"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "8.0")) (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."lucid" or (errorHandler.buildDepError "lucid"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."parsec" or (errorHandler.buildDepError "parsec"))
            (hsPkgs."bifunctors" or (errorHandler.buildDepError "bifunctors"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."lucid" or (errorHandler.buildDepError "lucid"))
          ];
          buildable = true;
        };
        "bench-io" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."lucid" or (errorHandler.buildDepError "lucid"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/lucid-2.11.20260427.tar.gz";
      sha256 = "6df595e65d46f018d8c4a7dc812523672c362ad1bedb583a4bf1c28f1b46b295";
    });
  }) // {
    package-description-override = "name:                lucid\nversion:             2.11.20260427\nsynopsis:            Clear to write, read and edit DSL for HTML\ndescription:\n  Clear to write, read and edit DSL for HTML.\n  .\n  * Names are consistent, and do not conflict with base or are keywords (all have suffix @_@)\n  .\n  * Same combinator can be used for attributes and elements (e.g. 'style_')\n  .\n  * For more, read <https://chrisdone.com/posts/lucid the blog post>\n  .\n  See the \"Lucid\" module for more documentation.\nhomepage:            https://github.com/chrisdone/lucid\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Chris Done\nmaintainer:          chrisdone@gmail.com\ncopyright:           2014-2021 Chris Done\ncategory:            Web\nbuild-type:          Simple\ncabal-version:       >=1.10\nextra-source-files:  README.md, CHANGELOG.md\ntested-with: GHC==7.10.3,GHC==8.0.2,GHC==8.2.2,GHC==8.4.4,GHC==8.6.5,GHC==8.8.4,GHC==8.10.7,GHC==9.0.1,GHC==9.2.1, GHC==9.4.1\n\nlibrary\n  default-language:  Haskell2010\n  hs-source-dirs:    src/\n  ghc-options:       -Wall -O2\n  exposed-modules:   Lucid\n                     Lucid.Base\n                     Lucid.Html5\n                     Lucid.Bootstrap\n\n  -- GHC boot libraries\n  build-depends:     base                   >=4.8      && <5\n                   , bytestring             >=0.10.6.0\n                   , containers             >=0.5.6.2\n                   , transformers           >=0.4.2.0\n\n  -- GHC boot libraries since 8.4.\n  build-depends:     mtl                    >=2.2\n                   , text                   >=1.2.0.2\n\n  -- compat packages\n  if !impl(ghc >= 8.0)\n    build-depends:   semigroups            >=0.16.1\n\n  -- other dependencies\n  build-depends:     blaze-builder         >=0.4.0.0\n                   , hashable              >=1.2.3.2\n                   , mmorph                >=1.0.3\n\nsource-repository head\n  type:     git\n  location: https://github.com/chrisdone/lucid.git\n\ntest-suite test\n    default-language: Haskell2010\n    type: exitcode-stdio-1.0\n    main-is: Main.hs\n    hs-source-dirs: test\n    other-modules: Example1\n    build-depends: base,\n                   lucid,\n                   HUnit,\n                   hspec,\n                   parsec,\n                   bifunctors,\n                   text,\n                   mtl\n\nbenchmark bench\n  default-language: Haskell2010\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   benchmarks\n  main-is:          Main.hs\n  other-modules:    HtmlBenchmarks\n  build-depends:    base,\n                    deepseq,\n                    criterion,\n                    blaze-builder,\n                    text,\n                    bytestring,\n                    lucid\n  ghc-options:      -O2\n\nbenchmark bench-io\n  default-language: Haskell2010\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   benchmarks\n  main-is:          IO.hs\n  build-depends:    base,\n                    criterion,\n                    transformers,\n                    text,\n                    lucid\n  ghc-options:      -O2\n";
  }