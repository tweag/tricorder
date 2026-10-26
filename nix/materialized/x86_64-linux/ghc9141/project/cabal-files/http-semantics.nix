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
      specVersion = "3.0";
      identifier = { name = "http-semantics"; version = "0.4.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Kazu Yamamoto <kazu@iij.ad.jp>";
      homepage = "https://github.com/kazu-yamamoto/http-semantics";
      url = "";
      synopsis = "HTTP semantics library";
      description = "Version-independent common parts of HTTP";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
          (hsPkgs."time-manager" or (errorHandler.buildDepError "time-manager"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/http-semantics-0.4.1.tar.gz";
      sha256 = "a02df11df8d5eabad028ce4c2d1efa889ae68e556dba94b0d13a7501797453db";
    });
  }) // {
    package-description-override = "cabal-version:   3.0\nname:            http-semantics\nversion:         0.4.1\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE\nmaintainer:      Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:          Kazu Yamamoto <kazu@iij.ad.jp>\nhomepage:        https://github.com/kazu-yamamoto/http-semantics\nsynopsis:        HTTP semantics library\ndescription:     Version-independent common parts of HTTP\ncategory:        Network\nbuild-type:      Simple\nextra-doc-files: ChangeLog.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/http-semantics\n\nlibrary\n    exposed-modules:\n        Network.HTTP.Semantics\n        Network.HTTP.Semantics.Client\n        Network.HTTP.Semantics.Client.Internal\n        Network.HTTP.Semantics.IO\n        Network.HTTP.Semantics.Server\n        Network.HTTP.Semantics.Server.Internal\n        Network.HTTP.Semantics.Token\n\n    other-modules:\n        Network.HTTP.Semantics.File\n        Network.HTTP.Semantics.FillBuf\n        Network.HTTP.Semantics.Header\n        Network.HTTP.Semantics.ReadN\n        Network.HTTP.Semantics.Status\n        Network.HTTP.Semantics.Trailer\n        Network.HTTP.Semantics.Types\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        array,\n        bytestring >=0.10,\n        case-insensitive,\n        http-types >=0.12 && <0.13,\n        network,\n        network-byte-order,\n        time-manager >= 0.2.4,\n        utf8-string\n";
  }