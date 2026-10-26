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
      identifier = { name = "network-byte-order"; version = "0.1.8"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "kazu@iij.ad.jp";
      author = "Kazu Yamamoto";
      homepage = "";
      url = "";
      synopsis = "Network byte order utilities";
      description = "Peek and poke functions for network byte order.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/network-byte-order-0.1.8.tar.gz";
      sha256 = "529766816e9e3fdb82fe1b147f8499ef482c30d15330d72088d8216ef640e741";
    });
  }) // {
    package-description-override = "cabal-version: >=1.10\nname:          network-byte-order\nversion:       0.1.8\nlicense:       BSD3\nlicense-file:  LICENSE\nmaintainer:    kazu@iij.ad.jp\nauthor:        Kazu Yamamoto\nsynopsis:      Network byte order utilities\ndescription:   Peek and poke functions for network byte order.\ncategory:      Network\nbuild-type:    Simple\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/network-byte-order.git\n\nlibrary\n    exposed-modules:    Network.ByteOrder\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        bytestring\n";
  }