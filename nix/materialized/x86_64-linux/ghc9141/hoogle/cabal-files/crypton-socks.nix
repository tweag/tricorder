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
    flags = { example = false; network-3-0-0-0 = true; };
    package = {
      specVersion = "1.18";
      identifier = { name = "crypton-socks"; version = "0.6.2"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Mike Pilgrem <public@pilgrem.com>,\nKazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "http://github.com/mpilgrem/crypton-socks";
      url = "";
      synopsis = "SOCKS Protocol Version 5";
      description = "A library implementing SOCKS Protocol Version 5.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
        ];
        buildable = true;
      };
      exes = {
        "crypton-socks-example" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton-socks" or (errorHandler.buildDepError "crypton-socks"))
          ] ++ (if flags.network-3-0-0-0
            then [
              (hsPkgs."network" or (errorHandler.buildDepError "network"))
              (hsPkgs."network-bsd" or (errorHandler.buildDepError "network-bsd"))
            ]
            else [
              (hsPkgs."network" or (errorHandler.buildDepError "network"))
            ]);
          buildable = if !flags.example then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-socks-0.6.2.tar.gz";
      sha256 = "a836087e5c277413c79e6d94a7bf346bfb61eaffb2f55555875c76dfeca69f3b";
    });
  }) // {
    package-description-override = "cabal-version: 1.18\r\n\r\n-- This file has been generated from package.yaml by hpack version 0.38.1.\r\n--\r\n-- see: https://github.com/sol/hpack\r\n\r\nname:           crypton-socks\r\nversion:        0.6.2\r\nsynopsis:       SOCKS Protocol Version 5\r\ndescription:    A library implementing SOCKS Protocol Version 5.\r\ncategory:       Network\r\nstability:      experimental\r\nhomepage:       http://github.com/mpilgrem/crypton-socks\r\nbug-reports:    https://github.com/mpilgrem/crypton-socks/issues\r\nauthor:         Vincent Hanquez <vincent@snarc.org>\r\nmaintainer:     Mike Pilgrem <public@pilgrem.com>,\r\n                Kazu Yamamoto <kazu@iij.ad.jp>\r\ncopyright:      Vincent Hanquez <vincent@snarc.org>\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nbuild-type:     Simple\r\nextra-doc-files:\r\n    CHANGELOG.md\r\n    README.md\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/mpilgrem/crypton-socks\r\n\r\nflag example\r\n  description: Build the example application.\r\n  manual: True\r\n  default: False\r\n\r\nflag network-3-0-0-0\r\n  description: Use network-3.0.0.0 or later. If used the example application has a dependency on network-bsd.\r\n  manual: False\r\n  default: True\r\n\r\nlibrary\r\n  exposed-modules:\r\n      Network.Socks5\r\n      Network.Socks5.Lowlevel\r\n      Network.Socks5.Types\r\n  other-modules:\r\n      Network.Socks5.Command\r\n      Network.Socks5.Conf\r\n      Network.Socks5.Parse\r\n      Network.Socks5.Wire\r\n  hs-source-dirs:\r\n      src\r\n  ghc-options: -Wall\r\n  build-depends:\r\n      base >=3 && <5\r\n    , bytestring\r\n    , cereal >=0.3.1\r\n    , network >=2.6\r\n  default-language: Haskell2010\r\n\r\nexecutable crypton-socks-example\r\n  main-is: Example.hs\r\n  hs-source-dirs:\r\n      example\r\n  ghc-options: -Wall\r\n  build-depends:\r\n      base >=3 && <5\r\n    , bytestring\r\n    , crypton-socks\r\n  default-language: Haskell2010\r\n  if !flag(example)\r\n    buildable: False\r\n  if flag(network-3-0-0-0)\r\n    build-depends:\r\n        network >=3.0.0.0\r\n      , network-bsd\r\n  else\r\n    build-depends:\r\n        network >=2.6\r\n";
  }