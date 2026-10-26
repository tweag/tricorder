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
      identifier = { name = "iproute"; version = "1.7.15"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Kazu Yamamoto <kazu@iij.ad.jp>";
      homepage = "http://www.mew.org/~kazu/proj/iproute/";
      url = "";
      synopsis = "IP Routing Table";
      description = "IP Routing Table is a tree of IP ranges\nto search one of them on the longest\nmatch base. It is a kind of TRIE with one\nway branching removed. Both IPv4 and IPv6\nare supported.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."appar" or (errorHandler.buildDepError "appar"))
          (hsPkgs."byteorder" or (errorHandler.buildDepError "byteorder"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.0") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."appar" or (errorHandler.buildDepError "appar"))
            (hsPkgs."byteorder" or (errorHandler.buildDepError "byteorder"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."safe" or (errorHandler.buildDepError "safe"))
            (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.0") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/iproute-1.7.15.tar.gz";
      sha256 = "18a331a7e0e6f9dc89a2da95577b0d76bd2690b8f832b72b46d6cc9b667b4ba5";
    });
  }) // {
    package-description-override = "cabal-version: >=1.10\nname:          iproute\nversion:       1.7.15\nlicense:       BSD3\nlicense-file:  LICENSE\nmaintainer:    Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:        Kazu Yamamoto <kazu@iij.ad.jp>\ntested-with:\n    ghc ==7.8.4 ghc ==7.10.3 ghc ==8.0.2 ghc ==8.2.2 ghc ==8.4.4\n    ghc ==8.6.5 ghc ==8.8.2\n\nhomepage:      http://www.mew.org/~kazu/proj/iproute/\nsynopsis:      IP Routing Table\ndescription:\n    IP Routing Table is a tree of IP ranges\n    to search one of them on the longest\n    match base. It is a kind of TRIE with one\n    way branching removed. Both IPv4 and IPv6\n    are supported.\n\ncategory:      Algorithms, Network\nbuild-type:    Simple\n\nsource-repository head\n    type:     git\n    location: git://github.com/kazu-yamamoto/iproute.git\n\nlibrary\n    exposed-modules:\n        Data.IP\n        Data.IP.Builder\n        Data.IP.Internal\n        Data.IP.RouteTable\n        Data.IP.RouteTable.Internal\n\n    other-modules:\n        Data.IP.Addr\n        Data.IP.Mask\n        Data.IP.Op\n        Data.IP.Range\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4.9 && <5,\n        appar,\n        byteorder,\n        bytestring,\n        containers,\n        network\n\n    if impl(ghc <8.0)\n        build-depends: semigroups >=0.17\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n\ntest-suite spec\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test\n    other-modules:\n        RouteTableSpec\n        BuilderSpec\n        IPSpec\n\n    default-language:   Haskell2010\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.6 && <5,\n        hspec,\n        QuickCheck,\n        appar,\n        byteorder,\n        bytestring,\n        containers,\n        network,\n        safe,\n        iproute\n\n    if impl(ghc <8.0)\n        build-depends: semigroups >=0.17\n";
  }