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
      specVersion = "2.2";
      identifier = { name = "utility-ht"; version = "0.0.17.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Henning Thielemann <haskell@henning-thielemann.de>";
      author = "Henning Thielemann <haskell@henning-thielemann.de>";
      homepage = "";
      url = "";
      synopsis = "Various small helper functions for Lists, Maybes, Tuples, Functions";
      description = "Various small helper functions for Lists, Maybes, Tuples, Functions.\nSome of these functions are improved implementations of standard functions.\nThey have the same name as their standard counterparts.\nOthers are equivalent to functions from the @base@ package,\nbut if you import them from this utility package\nthen you can write code that runs on older GHC versions\nor other compilers like Hugs and JHC.\n\nAll modules are plain Haskell 98.\nThe package depends exclusively on the @base@ package\nand only that portions of @base@ that are simple to port.\nThus you do not risk a dependency avalanche by importing it.\nHowever, further splitting the base package might invalidate this statement.\n\nAlternative packages: @Useful@, @MissingH@";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."doctest-exitcode-stdio" or (errorHandler.buildDepError "doctest-exitcode-stdio"))
            (hsPkgs."doctest-lib" or (errorHandler.buildDepError "doctest-lib"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/utility-ht-0.0.17.2.tar.gz";
      sha256 = "0a8ec081956d18f8ca84f58aacf39a5ab1a7dc08302e2ce28b4ac3768bb0372c";
    });
  }) // {
    package-description-override = "Cabal-Version:    2.2\nName:             utility-ht\nVersion:          0.0.17.2\nLicense:          BSD-3-Clause\nLicense-File:     LICENSE\nAuthor:           Henning Thielemann <haskell@henning-thielemann.de>\nMaintainer:       Henning Thielemann <haskell@henning-thielemann.de>\nCategory:         Data, List\nSynopsis:         Various small helper functions for Lists, Maybes, Tuples, Functions\nDescription:\n  Various small helper functions for Lists, Maybes, Tuples, Functions.\n  Some of these functions are improved implementations of standard functions.\n  They have the same name as their standard counterparts.\n  Others are equivalent to functions from the @base@ package,\n  but if you import them from this utility package\n  then you can write code that runs on older GHC versions\n  or other compilers like Hugs and JHC.\n  .\n  All modules are plain Haskell 98.\n  The package depends exclusively on the @base@ package\n  and only that portions of @base@ that are simple to port.\n  Thus you do not risk a dependency avalanche by importing it.\n  However, further splitting the base package might invalidate this statement.\n  .\n  Alternative packages: @Useful@, @MissingH@\nTested-With:       GHC==7.0.2, GHC==7.2.2, GHC==7.4.2, GHC==7.8.4\nTested-With:       GHC==8.6.5, GHC==9.4.5, GHC==9.6.1\nBuild-Type:        Simple\nStability:         Stable\n\nExtra-Source-Files:\n  Makefile\n\nSource-Repository head\n  type:     darcs\n  location: http://code.haskell.org/~thielema/utility/\n\nSource-Repository this\n  type:     darcs\n  location: http://code.haskell.org/~thielema/utility/\n  tag:      0.0.17.2\n\nLibrary\n  Build-Depends:\n    base >=2 && <5\n\n  Default-Language: Haskell98\n  GHC-Options:      -Wall\n  Hs-Source-Dirs:   src\n  Exposed-Modules:\n    Data.Bits.HT\n    Data.Bool.HT\n    Data.Eq.HT\n    Data.Function.HT\n    Data.Ix.Enum\n    Data.List.HT\n    Data.List.Key\n    Data.List.Match\n    Data.List.Reverse.StrictElement\n    Data.List.Reverse.StrictSpine\n    Data.Maybe.HT\n    Data.Either.HT\n    Data.Monoid.HT\n    Data.Ord.HT\n    Data.Record.HT\n    Data.String.HT\n    Data.Tuple.HT\n    Data.Tuple.Lazy\n    Data.Tuple.Strict\n    Control.Monad.HT\n    Control.Applicative.HT\n    Control.Functor.HT\n    Data.Strictness.HT\n    Text.Read.HT\n    Text.Show.HT\n  Other-Modules:\n    Data.Bool.HT.Private\n    Data.List.HT.Private\n    Data.List.Key.Private\n    Data.List.Match.Private\n    Data.List.Reverse.Private\n    Data.Function.HT.Private\n    Data.Record.HT.Private\n    Data.Tuple.Example\n\n\nTest-Suite test\n  Type:             exitcode-stdio-1.0\n  Build-Depends:\n    QuickCheck >=1.1 && <3,\n    doctest-exitcode-stdio >=0.0 && <0.1,\n    doctest-lib >=0.1 && <0.1.2,\n    base >=3 && <5\n  Default-Language: Haskell98\n  Main-Is:          Test.hs\n  GHC-Options:      -Wall\n  Hs-source-dirs:   src\n  Other-Modules:\n    Test.Utility\n    DocTest.Data.List.Reverse.StrictElement\n    DocTest.Data.List.Reverse.StrictSpine\n    DocTest.Data.List.Reverse.Private\n    DocTest.Data.List.Match.Private\n    DocTest.Data.List.HT.Private\n    DocTest.Data.Monoid.HT\n    DocTest.Data.Maybe.HT\n    DocTest.Data.Bool.HT.Private\n    DocTest.Data.Function.HT.Private\n    DocTest.Data.Ix.Enum\n";
  }