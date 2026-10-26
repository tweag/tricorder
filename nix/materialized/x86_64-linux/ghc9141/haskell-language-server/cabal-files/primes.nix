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
      specVersion = "1.6";
      identifier = { name = "primes"; version = "0.2.1.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Sebastian Fischer";
      author = "Sebastian Fischer";
      homepage = "http://github.com/sebfisch/primes";
      url = "";
      synopsis = "Efficient, purely functional generation of prime numbers";
      description = "This Haskell library provides an efficient lazy wheel sieve for\nprime generation inspired by /Lazy wheel sieves and spirals of/\n/primes/ by Colin Runciman and /The Genuine Sieve of Eratosthenes/\nby Melissa O'Neil.";
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
      url = "http://hackage.haskell.org/package/primes-0.2.1.0.tar.gz";
      sha256 = "74d66558fb638ea4d31eae2fe1a294cb5a9d64491314305d74a11d93f277c65b";
    });
  }) // {
    package-description-override = "Name:          primes\nVersion:       0.2.1.0\nCabal-Version: >= 1.6\nSynopsis:      Efficient, purely functional generation of prime numbers\nDescription:\n\n  This Haskell library provides an efficient lazy wheel sieve for\n  prime generation inspired by /Lazy wheel sieves and spirals of/\n  /primes/ by Colin Runciman and /The Genuine Sieve of Eratosthenes/\n  by Melissa O'Neil.\n\nCategory:      Algorithms, Numerical\nLicense:       BSD3\nLicense-File:  LICENSE\nAuthor:        Sebastian Fischer\nMaintainer:    Sebastian Fischer\nBug-Reports:   http://github.com/sebfisch/primes/issues\nHomepage:      http://github.com/sebfisch/primes\nBuild-Type:    Simple\nStability:     experimental\n\nExtra-Source-Files: README, memory.hs, runtime.hs\n\nLibrary\n  Build-Depends:    base == 4.*\n  Exposed-Modules:  Data.Numbers.Primes\n  Ghc-Options:      -Wall -fno-warn-incomplete-patterns\n\nSource-Repository head\n  type:     git\n  location: git://github.com/sebfisch/primes.git\n";
  }