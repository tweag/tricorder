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
    flags = { build-readme = true; };
    package = {
      specVersion = "2.0";
      identifier = { name = "constraints-extras"; version = "0.4.0.2"; };
      license = "BSD-3-Clause";
      copyright = "Obsidian Systems LLC";
      maintainer = "maintainer@obsidian.systems";
      author = "Cale Gibbard, Ali Abrar";
      homepage = "https://github.com/obsidiansystems/constraints-extras";
      url = "";
      synopsis = "Utility package for constraints";
      description = "Convenience functions and TH for working with constraints. See <https://github.com/obsidiansystems/constraints-extras/blob/develop/README.md README.md> for example usage.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."constraints" or (errorHandler.buildDepError "constraints"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "9.12") (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"));
        buildable = true;
      };
      exes = {
        "readme" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."constraints" or (errorHandler.buildDepError "constraints"))
            (hsPkgs."constraints-extras" or (errorHandler.buildDepError "constraints-extras"))
          ];
          buildable = if !flags.build-readme then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/constraints-extras-0.4.0.2.tar.gz";
      sha256 = "cc7fdb2625f1baeb16501176d8e2eb6da16a3448f2f0a37e188289c503cb482c";
    });
  }) // {
    package-description-override = "name: constraints-extras\r\nversion: 0.4.0.2\r\nx-revision: 1\r\nsynopsis: Utility package for constraints\r\ndescription: Convenience functions and TH for working with constraints. See <https://github.com/obsidiansystems/constraints-extras/blob/develop/README.md README.md> for example usage.\r\ncategory: Constraints\r\nlicense: BSD3\r\nlicense-file: LICENSE\r\nauthor: Cale Gibbard, Ali Abrar\r\nmaintainer: maintainer@obsidian.systems\r\nhomepage: https://github.com/obsidiansystems/constraints-extras\r\nbug-reports: https://github.com/obsidiansystems/constraints-extras/issues\r\ncopyright: Obsidian Systems LLC\r\nbuild-type: Simple\r\ncabal-version: 2.0\r\ntested-with:\r\n  GHC ==8.6.5 || ==8.8.4 || ==8.10.7\r\n   || ==9.0.2 || ==9.2.8 || ==9.4.8 || ==9.6.6 || ==9.8.4 || ==9.10.1 || ==9.12.1\r\nextra-doc-files: ChangeLog.md\r\nextra-source-files: README.md\r\n\r\nflag build-readme\r\n  default: True\r\n\r\nlibrary\r\n  exposed-modules: Data.Constraint.Extras\r\n                 , Data.Constraint.Extras.TH\r\n                 , Data.Constraint.Compose\r\n                 , Data.Constraint.Flip\r\n  other-extensions: LambdaCase\r\n                  , MultiParamTypeClasses\r\n                  , QuasiQuotes\r\n                  , TypeFamilies\r\n                  , TypeOperators\r\n                  , ConstraintKinds\r\n                  , TemplateHaskell\r\n  build-depends: base >=4.9 && <4.23\r\n               , constraints >= 0.9 && < 0.15\r\n               , template-haskell >=2.11 && <2.25\r\n\r\n  hs-source-dirs:  src\r\n  default-language: Haskell2010\r\n\r\n  -- This is needed to get around a bug/misfeature in the cabal solver which is choosing an\r\n  -- old version of aeson (0.9.*) for some reason.\r\n  if impl (ghc >= 9.12)\r\n    build-depends: aeson >= 2\r\n\r\n\r\nexecutable readme\r\n  if !flag(build-readme)\r\n    buildable: False\r\n  build-depends: base\r\n               , aeson\r\n               , constraints\r\n               , constraints-extras\r\n  main-is: README.lhs\r\n  ghc-options: -Wall -optL -q\r\n  default-language: Haskell2010\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: git://github.com/obsidiansystems/constraints-extras.git\r\n";
  }