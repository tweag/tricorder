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
      identifier = { name = "hourglass"; version = "0.2.12"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "vincent@snarc.org";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/vincenthz/hs-hourglass";
      url = "";
      synopsis = "simple performant time related library";
      description = "Simple time library focusing on simple but powerful and performant API\n\nThe backbone of the library are the Timeable and Time type classes.\n\nEach Timeable instances can be converted to type that has a Time instances,\nand thus are different representations of current time.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ] ++ pkgs.lib.optional (system.isWindows) (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"));
        buildable = true;
      };
      tests = {
        "test-hourglass" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."old-locale" or (errorHandler.buildDepError "old-locale"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench-hourglass" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."gauge" or (errorHandler.buildDepError "gauge"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."old-locale" or (errorHandler.buildDepError "old-locale"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hourglass-0.2.12.tar.gz";
      sha256 = "44335b5c402e80c60f1db6a74462be4ea29d1a9043aa994334ffee1164f1ca4a";
    });
  }) // {
    package-description-override = "Name:                hourglass\r\nVersion:             0.2.12\r\nx-revision: 1\r\nSynopsis:            simple performant time related library\r\nDescription:\r\n    Simple time library focusing on simple but powerful and performant API\r\n    .\r\n    The backbone of the library are the Timeable and Time type classes.\r\n    .\r\n    Each Timeable instances can be converted to type that has a Time instances,\r\n    and thus are different representations of current time.\r\nLicense:             BSD3\r\nLicense-file:        LICENSE\r\nCopyright:           Vincent Hanquez <vincent@snarc.org>\r\nAuthor:              Vincent Hanquez <vincent@snarc.org>\r\nMaintainer:          vincent@snarc.org\r\nCategory:            Time\r\nStability:           experimental\r\nBuild-Type:          Simple\r\nHomepage:            https://github.com/vincenthz/hs-hourglass\r\nCabal-Version:       >=1.10\r\nextra-source-files:  README.md\r\n                  ,  CHANGELOG.md\r\n                  ,  tests/TimeDB.hs\r\n\r\nLibrary\r\n  Exposed-modules:   Time.Types\r\n                   , Time.System\r\n                   , Time.Compat\r\n                   , Data.Hourglass\r\n                   , Data.Hourglass.Types\r\n                   , Data.Hourglass.Epoch\r\n                   , Data.Hourglass.Compat\r\n                   , System.Hourglass\r\n  Other-modules:     Data.Hourglass.Time\r\n                   , Data.Hourglass.Format\r\n                   , Data.Hourglass.Diff\r\n                   , Data.Hourglass.Local\r\n                   , Data.Hourglass.Calendar\r\n                   , Data.Hourglass.Zone\r\n                   , Data.Hourglass.Internal\r\n                   , Data.Hourglass.Utils\r\n  Build-depends:     base >= 4 && < 5\r\n                   , deepseq\r\n  ghc-options:       -Wall -fwarn-tabs\r\n  Default-Language:  Haskell2010\r\n  if os(windows)\r\n     cpp-options:    -DWINDOWS\r\n     Build-depends:  Win32\r\n     Other-modules:  Data.Hourglass.Internal.Win\r\n  else\r\n     Other-modules:  Data.Hourglass.Internal.Unix\r\n     c-sources:      cbits/unix.c\r\n\r\nTest-Suite test-hourglass\r\n  type:              exitcode-stdio-1.0\r\n  hs-source-dirs:    tests\r\n  Main-is:           Tests.hs\r\n  Build-Depends:     base >= 3 && < 5\r\n                   , mtl\r\n                   , tasty\r\n                   , tasty-quickcheck\r\n                   , tasty-hunit\r\n                   , hourglass\r\n                   , deepseq\r\n                   -- to test against some other reference\r\n                   , time < 1.10\r\n                   , old-locale\r\n  ghc-options:       -Wall -fno-warn-orphans -fno-warn-missing-signatures\r\n  Default-Language:  Haskell2010\r\n  if os(windows)\r\n     cpp-options:    -DWINDOWS\r\n\r\nBenchmark bench-hourglass\r\n  hs-source-dirs:    tests\r\n  Main-Is:           Bench.hs\r\n  type:              exitcode-stdio-1.0\r\n  Default-Language:  Haskell2010\r\n  Build-depends:     base >= 4 && < 5\r\n                   , bytestring\r\n                   , gauge\r\n                   , mtl\r\n                   , deepseq\r\n                   , hourglass\r\n                   -- to benchmark against other reference\r\n                   , time\r\n                   , old-locale\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/vincenthz/hs-hourglass\r\n";
  }