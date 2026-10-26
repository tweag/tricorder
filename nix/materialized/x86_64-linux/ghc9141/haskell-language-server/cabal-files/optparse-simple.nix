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
    flags = { build-example = false; };
    package = {
      specVersion = "1.12";
      identifier = { name = "optparse-simple"; version = "0.1.1.4"; };
      license = "BSD-3-Clause";
      copyright = "2015-2017 FP Complete";
      maintainer = "chrisdone@fpcomplete.com";
      author = "FP Complete";
      homepage = "https://github.com/fpco/optparse-simple#readme";
      url = "";
      synopsis = "Simple interface to optparse-applicative";
      description = "Please see the README at <https://www.stackage.org/package/optparse-simple>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."githash" or (errorHandler.buildDepError "githash"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-compat" or (errorHandler.buildDepError "th-compat"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.0") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
        buildable = true;
      };
      exes = {
        "simple" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."optparse-simple" or (errorHandler.buildDepError "optparse-simple"))
          ];
          buildable = if flags.build-example then true else false;
        };
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."optparse-simple" or (errorHandler.buildDepError "optparse-simple"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/optparse-simple-0.1.1.4.tar.gz";
      sha256 = "1d01d85c477b42e5a6ab6595def68c800d5bccbeff5a06ccf63c6a86967a7878";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.34.4.\n--\n-- see: https://github.com/sol/hpack\n\nname:           optparse-simple\nversion:        0.1.1.4\nsynopsis:       Simple interface to optparse-applicative\ndescription:    Please see the README at <https://www.stackage.org/package/optparse-simple>\ncategory:       Options\nhomepage:       https://github.com/fpco/optparse-simple#readme\nbug-reports:    https://github.com/fpco/optparse-simple/issues\nauthor:         FP Complete\nmaintainer:     chrisdone@fpcomplete.com\ncopyright:      2015-2017 FP Complete\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/fpco/optparse-simple\n\nflag build-example\n  description: Build the example executable\n  manual: True\n  default: False\n\nlibrary\n  exposed-modules:\n      Options.Applicative.Simple\n  other-modules:\n      Paths_optparse_simple\n  hs-source-dirs:\n      src/\n  ghc-options: -Wall\n  build-depends:\n      base >=4.9.1 && <5\n    , githash >=0.1.3.0\n    , optparse-applicative\n    , template-haskell\n    , th-compat\n    , transformers >=0.4\n  if impl (ghc < 8.0)\n    build-depends:\n        semigroups ==0.18.*\n  default-language: Haskell2010\n\nexecutable simple\n  main-is: example/Simple.hs\n  other-modules:\n      Paths_optparse_simple\n  build-depends:\n      base >=4.9.1 && <5\n    , optparse-simple\n  if flag(build-example)\n    buildable: True\n  else\n    buildable: False\n  default-language: Haskell2010\n\ntest-suite test\n  type: exitcode-stdio-1.0\n  main-is: Main.hs\n  other-modules:\n      Paths_optparse_simple\n  hs-source-dirs:\n      test\n  ghc-options: -Wall\n  build-depends:\n      base\n    , bytestring\n    , directory\n    , optparse-simple\n  default-language: Haskell2010\n";
  }