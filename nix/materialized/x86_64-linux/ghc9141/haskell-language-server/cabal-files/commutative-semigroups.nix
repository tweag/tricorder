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
      specVersion = "2.4";
      identifier = { name = "commutative-semigroups"; version = "0.2.0.2"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2013 Nathan van Doorn, 2021–2022 Obsidian Systems LLC";
      maintainer = "maintainer@obsidian.systems";
      author = "Nathan \"Taneb\" van Doorn";
      homepage = "";
      url = "";
      synopsis = "Commutative semigroups";
      description = "A commutative semigroup is a semigroup where the order of arguments to mappend does not matter.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/commutative-semigroups-0.2.0.2.tar.gz";
      sha256 = "f824b1d69925627a76277655aaccb0041b782fb3810fbe948dde3c2107af471b";
    });
  }) // {
    package-description-override = "cabal-version:       2.4\nname:                commutative-semigroups\nversion:             0.2.0.2\nsynopsis:            Commutative semigroups\ndescription:\n  A commutative semigroup is a semigroup where the order of arguments to mappend does not matter.\nlicense:             BSD-3-Clause\nlicense-file:        LICENSE\nauthor:              Nathan \"Taneb\" van Doorn\nmaintainer:          maintainer@obsidian.systems\ncopyright:           Copyright (C) 2013 Nathan van Doorn, 2021–2022 Obsidian Systems LLC\ncategory:            Algebra, Data, Math\nbuild-type:          Simple\nbug-reports:         https://github.com/ObsidianSystems/commutative-semigroups/issues\nextra-source-files:\n  ChangeLog.md\n  ReadMe.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/ObsidianSystems/commutative-semigroups.git\n\nlibrary\n  exposed-modules:     Data.Semigroup.Commutative\n                       Numeric.Product.Commutative\n  -- other-modules:\n  build-depends:       base >= 4.6 && < 5,\n                       containers >= 0.4 && < 0.9\n  hs-source-dirs:      src\n  default-language:    Haskell2010\n";
  }