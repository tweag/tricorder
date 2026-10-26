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
    flags = { semigroupoids = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "semialign"; version = "1.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "C. McCann, Oleg Grenrus";
      homepage = "https://github.com/haskellari/these";
      url = "";
      synopsis = "Align and Zip type-classes from the common Semialign ancestor.";
      description = "The major use of @These@ of this is provided by the @align@ member of\n@Semialign@ class, representing a generalized notion of \"zipping with padding\"\nthat combines structures without truncating to the size of the smaller input.\n\nIt turns out that @zip@ operation fits well the @Semialign@ class,\nforming lattice-like structure.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."these" or (errorHandler.buildDepError "these"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."indexed-traversable" or (errorHandler.buildDepError "indexed-traversable"))
          (hsPkgs."indexed-traversable-instances" or (errorHandler.buildDepError "indexed-traversable-instances"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ] ++ pkgs.lib.optional (flags.semigroupoids) (hsPkgs."semigroupoids" or (errorHandler.buildDepError "semigroupoids"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/semialign-1.4.tar.gz";
      sha256 = "0f51389e57af646042dcec2511960617bee2857231ac291228cf4ef6621a9464";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               semialign\nversion:            1.4\nsynopsis:\n  Align and Zip type-classes from the common Semialign ancestor.\n\nhomepage:           https://github.com/haskellari/these\nlicense:            BSD3\nlicense-file:       LICENSE\nauthor:             C. McCann, Oleg Grenrus\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\ncategory:           Data, These\nbuild-type:         Simple\nextra-source-files: CHANGELOG.md\ndescription:\n  The major use of @These@ of this is provided by the @align@ member of\n  @Semialign@ class, representing a generalized notion of \"zipping with padding\"\n  that combines structures without truncating to the size of the smaller input.\n  .\n  It turns out that @zip@ operation fits well the @Semialign@ class,\n  forming lattice-like structure.\n\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.1\n   || ==9.12.4\n   || ==9.14.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskellari/these.git\n  subdir:   semialign\n\nflag semigroupoids\n  description: Build with semigroupoids dependency\n  manual:      True\n  default:     True\n\nlibrary\n  default-language: Haskell2010\n  ghc-options:      -Wall -Wno-trustworthy-safe\n\n  if impl(ghc >=9.2)\n    ghc-options: -Wno-noncanonical-monoid-instances\n\n  hs-source-dirs:   src\n  exposed-modules:\n    Data.Align\n    Data.Crosswalk\n    Data.Semialign\n    Data.Semialign.Indexed\n    Data.Zip\n\n  other-modules:    Data.Semialign.Internal\n\n  -- ghc boot libs\n  build-depends:\n      base          >=4.12.0.0 && <4.23\n    , containers    >=0.6.0.1  && <0.9\n\n  -- These\n  build-depends:    these >=1.2.1 && <1.3\n\n  -- other dependencies\n  build-depends:\n      hashable                       >=1.4.4.0  && <1.6\n    , indexed-traversable            >=0.1.4    && <0.2\n    , indexed-traversable-instances  >=0.1.2    && <0.2\n    , tagged                         >=0.8.8    && <0.9\n    , unordered-containers           >=0.2.8.0  && <0.3\n    , vector                         >=0.13.0.0 && <0.14\n\n  if flag(semigroupoids)\n    build-depends: semigroupoids >=6.0.1 && <6.1\n";
  }