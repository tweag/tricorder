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
      identifier = { name = "strict"; version = "0.5.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2006-2008 by Roman Leshchinskiy\n(c) 2013-2014 by Simon Meier";
      maintainer = "Don Stewart <dons@galois.com>,\nBas van Dijk <v.dijk.bas@gmail.com>,\nOleg Grenrus <oleg.grenrus@iki.fi>,\nSimon Meier <iridcode@gmail.com>,\nXimin Luo <infinity0@pwned.gg>";
      author = "Roman Leshchinskiy <rl@cse.unsw.edu.au>\nSimon Meier <iridcode@gmail.com>";
      homepage = "https://github.com/haskell-strict/strict";
      url = "";
      synopsis = "Strict data types and String IO.";
      description = "This package provides strict versions of some standard Haskell data\ntypes (pairs, Maybe and Either). It also contains strict IO operations.\n\nIt is common knowledge that lazy datastructures can lead to space-leaks.\nThis problem is particularly prominent, when using lazy datastructures to\nstore the state of a long-running application in memory. One common\nsolution to this problem is to use @seq@ and its variants in every piece of\ncode that updates your state. However a much easier solution is to use\nfully strict types to store such state values. By \\\"fully strict types\\\" we\nmean types for whose values it holds that, if they are in weak-head normal\nform, then they are also in normal form. Intuitively, this means that\nvalues of fully strict types cannot contain unevaluated thunks.\n\nTo define a fully strict datatype, one typically uses the following recipe.\n\n1. Make all fields of every constructor strict; i.e., add a bang to\nall fields.\n\n2. Use only strict types for the fields of the constructors.\n\nThe second requirement is problematic as it rules out the use of\nthe standard Haskell 'Maybe', 'Either', and pair types. This library\nsolves this problem by providing strict variants of these types and their\ncorresponding standard support functions and type-class instances.\n\nNote that this library does currently not provide fully strict lists.\nThey can be added if they are really required. However, in many cases one\nprobably wants to use unboxed or strict boxed vectors from the 'vector'\nlibrary (<http://hackage.haskell.org/package/vector>) instead of strict\nlists.  Moreover, instead of @String@s one probably wants to use strict\n@Text@ values from the @text@ library\n(<http://hackage.haskell.org/package/text>).\n\nThis library comes with batteries included; i.e., mirror functions and\ninstances of the lazy versions in @base@. It also includes instances for\ntype-classes from the @deepseq@, @binary@, and @hashable@ packages.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."assoc" or (errorHandler.buildDepError "assoc"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."these" or (errorHandler.buildDepError "these"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/strict-0.5.1.tar.gz";
      sha256 = "77719280c2a86312e748227bfa732eeaae0e7df48d57acc3c2e5b7b07afe2f8b";
    });
  }) // {
    package-description-override = "name:               strict\nversion:            0.5.1\nx-revision:         1\nsynopsis:           Strict data types and String IO.\ncategory:           Data, System\ndescription:\n  This package provides strict versions of some standard Haskell data\n  types (pairs, Maybe and Either). It also contains strict IO operations.\n  .\n  It is common knowledge that lazy datastructures can lead to space-leaks.\n  This problem is particularly prominent, when using lazy datastructures to\n  store the state of a long-running application in memory. One common\n  solution to this problem is to use @seq@ and its variants in every piece of\n  code that updates your state. However a much easier solution is to use\n  fully strict types to store such state values. By \\\"fully strict types\\\" we\n  mean types for whose values it holds that, if they are in weak-head normal\n  form, then they are also in normal form. Intuitively, this means that\n  values of fully strict types cannot contain unevaluated thunks.\n  .\n  To define a fully strict datatype, one typically uses the following recipe.\n  .\n  1. Make all fields of every constructor strict; i.e., add a bang to\n  all fields.\n  .\n  2. Use only strict types for the fields of the constructors.\n  .\n  The second requirement is problematic as it rules out the use of\n  the standard Haskell 'Maybe', 'Either', and pair types. This library\n  solves this problem by providing strict variants of these types and their\n  corresponding standard support functions and type-class instances.\n  .\n  Note that this library does currently not provide fully strict lists.\n  They can be added if they are really required. However, in many cases one\n  probably wants to use unboxed or strict boxed vectors from the 'vector'\n  library (<http://hackage.haskell.org/package/vector>) instead of strict\n  lists.  Moreover, instead of @String@s one probably wants to use strict\n  @Text@ values from the @text@ library\n  (<http://hackage.haskell.org/package/text>).\n  .\n  This library comes with batteries included; i.e., mirror functions and\n  instances of the lazy versions in @base@. It also includes instances for\n  type-classes from the @deepseq@, @binary@, and @hashable@ packages.\n\nlicense:            BSD3\nlicense-file:       LICENSE\nauthor:\n  Roman Leshchinskiy <rl@cse.unsw.edu.au>\n  Simon Meier <iridcode@gmail.com>\n\nmaintainer:\n  Don Stewart <dons@galois.com>,\n  Bas van Dijk <v.dijk.bas@gmail.com>,\n  Oleg Grenrus <oleg.grenrus@iki.fi>,\n  Simon Meier <iridcode@gmail.com>,\n  Ximin Luo <infinity0@pwned.gg>\n\ncopyright:\n  (c) 2006-2008 by Roman Leshchinskiy\n  (c) 2013-2014 by Simon Meier\n\nhomepage:           https://github.com/haskell-strict/strict\ncabal-version:      >=1.10\nbuild-type:         Simple\nextra-source-files: CHANGELOG.md\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.2\n   || ==9.10.1\n\nlibrary\n  default-language: Haskell2010\n  hs-source-dirs:   src\n  ghc-options:      -Wall\n  build-depends:\n      assoc         >=1.1.1    && <1.2\n    , base          >=4.12.0.0 && <5\n    , binary        >=0.8.6.0  && <0.9\n    , bytestring    >=0.10.8.2 && <0.13\n    , deepseq       >=1.4.4.0  && <1.6\n    , ghc-prim\n    , hashable      >=1.4.7.0  && <1.6\n    , text          >=1.2.3.1  && <1.3  || >=2.0 && <2.2\n    , these         >=1.2.1    && <1.3\n    , transformers  >=0.5.6.2  && <0.7\n\n  exposed-modules:\n    Data.Strict\n    Data.Strict.Classes\n    Data.Strict.Either\n    Data.Strict.Maybe\n    Data.Strict.These\n    Data.Strict.Tuple\n    System.IO.Strict\n";
  }