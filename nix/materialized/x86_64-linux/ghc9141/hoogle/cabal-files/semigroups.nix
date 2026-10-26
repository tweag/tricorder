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
      identifier = { name = "semigroups"; version = "0.20.1"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2011-2015 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/semigroups/";
      url = "";
      synopsis = "Anything that associates";
      description = "In mathematics, a semigroup is an algebraic structure consisting of a set together with an associative binary operation. A semigroup generalizes a monoid in that there might not exist an identity element. It also (originally) generalized a group (a monoid with all inverses) to a type where every element did not have to have an inverse, thus the name semigroup.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/semigroups-0.20.1.tar.gz";
      sha256 = "bf4c71224397c3777e6a79145f5c9c31d5a13f27548345e55138461d87348ffe";
    });
  }) // {
    package-description-override = "name:          semigroups\ncategory:      Algebra, Data, Data Structures, Math\nversion:       0.20.1\nlicense:       BSD3\ncabal-version: >= 1.10\nlicense-file:  LICENSE\nauthor:        Edward A. Kmett\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\nstability:     provisional\nhomepage:      http://github.com/ekmett/semigroups/\nbug-reports:   http://github.com/ekmett/semigroups/issues\ncopyright:     Copyright (C) 2011-2015 Edward A. Kmett\nsynopsis:      Anything that associates\ndescription:\n    In mathematics, a semigroup is an algebraic structure consisting of a set together with an associative binary operation. A semigroup generalizes a monoid in that there might not exist an identity element. It also (originally) generalized a group (a monoid with all inverses) to a type where every element did not have to have an inverse, thus the name semigroup.\nbuild-type:    Simple\nextra-source-files: README.markdown CHANGELOG.markdown\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.3\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nsource-repository head\n  type: git\n  location: https://github.com/ekmett/semigroups.git\n\nlibrary\n  default-language: Haskell98\n  hs-source-dirs: src\n  ghc-options: -Wall\n\n  build-depends: base >= 4.9 && < 5\n  exposed-modules:\n    Data.Semigroup.Generic\n";
  }