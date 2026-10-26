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
      identifier = { name = "monoid-subclasses"; version = "1.2.6.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2013-2024 Mario Blažević";
      maintainer = "Mario Blažević <blamario@protonmail.com>";
      author = "Mario Blažević";
      homepage = "https://github.com/blamario/monoid-subclasses/";
      url = "";
      synopsis = "Subclasses of Monoid";
      description = "A hierarchy of subclasses of 'Monoid' together with their instances for all data structures from base, containers, and\ntext packages.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."primes" or (errorHandler.buildDepError "primes"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."commutative-semigroups" or (errorHandler.buildDepError "commutative-semigroups"))
        ];
        buildable = true;
      };
      tests = {
        "Main" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."primes" or (errorHandler.buildDepError "primes"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."monoid-subclasses" or (errorHandler.buildDepError "monoid-subclasses"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/monoid-subclasses-1.2.6.1.tar.gz";
      sha256 = "16afba4025da689a76c98643d30ea1be53d2bc16f3ddc9de15621c21760e5c96";
    });
  }) // {
    package-description-override = "Name:                monoid-subclasses\nVersion:             1.2.6.1\nCabal-Version:       >= 1.10\nBuild-Type:          Simple\nSynopsis:            Subclasses of Monoid\nCategory:            Data, Algebra, Text\nTested-with:         GHC==8.0.2\n                   , GHC==8.2.2\n                   , GHC==8.4.4\n                   , GHC==8.6.5\n                   , GHC==8.8.4\n                   , GHC==8.10.7\n                   , GHC==9.0.2\n                   , GHC==9.2.8\n                   , GHC==9.4.8\n                   , GHC==9.6.6\n                   , GHC==9.8.4\n                   , GHC==9.10.1\n                   , GHC==9.12.1\n\nDescription:\n  A hierarchy of subclasses of 'Monoid' together with their instances for all data structures from base, containers, and\n  text packages.\n\nLicense:             BSD3\nLicense-file:        BSD3-LICENSE.txt\nCopyright:           (c) 2013-2024 Mario Blažević\nAuthor:              Mario Blažević\nMaintainer:          Mario Blažević <blamario@protonmail.com>\nHomepage:            https://github.com/blamario/monoid-subclasses/\nBug-reports:         https://github.com/blamario/monoid-subclasses/issues\nExtra-Source-Files:  README.md, CHANGELOG.md\nSource-repository head\n  type:              git\n  location:          https://github.com/blamario/monoid-subclasses\n\nLibrary\n  hs-source-dirs:    src\n  Exposed-Modules:\n                     Data.Monoid.Cancellative\n                   , Data.Monoid.Factorial\n                   , Data.Monoid.GCD\n                   , Data.Monoid.Instances.ByteString.UTF8\n                   , Data.Monoid.Instances.CharVector\n                   , Data.Monoid.Instances.Concat\n                   , Data.Monoid.Instances.Measured\n                   , Data.Monoid.Instances.Positioned\n                   , Data.Monoid.Instances.PrefixMemory\n                   , Data.Monoid.Instances.Stateful\n                   , Data.Monoid.LCM\n                   , Data.Monoid.Monus\n                   , Data.Monoid.Null\n                   , Data.Monoid.Textual\n                   , Data.Semigroup.Cancellative\n                   , Data.Semigroup.Factorial\n  Build-Depends:     base >= 4.9 && < 5,\n                     bytestring >= 0.9 && < 1.0,\n                     containers >= 0.5.7.0 && < 0.9,\n                     text >= 0.11 && < 1.3 || >= 2.0 && < 2.2,\n                     primes == 0.2.*,\n                     vector >= 0.12 && < 0.14,\n                     commutative-semigroups >= 0.1 && < 0.3\n  GHC-options:       -Wall\n  default-language:  Haskell2010\n\ntest-suite Main\n  Type:              exitcode-stdio-1.0\n  Build-Depends:     base >= 4.9 && < 5,\n                     bytestring, containers, text, vector, primes,\n                     QuickCheck >= 2.9 && < 3, quickcheck-instances >= 0.3.12 && <0.5,\n                     tasty >= 0.7, tasty-quickcheck >= 0.7 && < 1.0,\n                     monoid-subclasses\n  Main-is:           Test/TestMonoidSubclasses.hs\n  default-language:  Haskell2010\n";
  }