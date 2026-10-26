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
      identifier = { name = "hw-fingertree"; version = "0.1.1.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2017-2019 John Ky\n(c) 2006 Ross Paterson, Ralf Hinze,";
      maintainer = "John Ky <newhoggy@gmail.com>";
      author = "";
      homepage = "https://github.com/haskell-works/hw-fingertree#readme";
      url = "";
      synopsis = "Generic finger-tree structure, with example instances";
      description = "A general sequence representation with arbitrary\nannotations, for use as a base for implementations of\nvarious collection types, with examples, as described\nin section 4 of\n\n* Ralf Hinze and Ross Paterson,\n\\\"Finger trees: a simple general-purpose data structure\\\",\n/Journal of Functional Programming/ 16:2 (2006) pp 197-217.\n<http://staff.city.ac.uk/~ross/papers/FingerTree.html>\n\nFor a tuned sequence type, see @Data.Sequence@ in the\n@containers@ package, which is a specialization of\nthis structure.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."hw-prim" or (errorHandler.buildDepError "hw-prim"))
        ];
        buildable = true;
      };
      tests = {
        "hw-fingertree-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hw-hspec-hedgehog" or (errorHandler.buildDepError "hw-hspec-hedgehog"))
            (hsPkgs."hw-fingertree" or (errorHandler.buildDepError "hw-fingertree"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hw-fingertree-0.1.1.0.tar.gz";
      sha256 = "be42dbba876e4d730a959b957c67c8315f6f2a432e5a39a8f2774c0f9791d424";
    });
  }) // {
    package-description-override = "cabal-version:  2.2\n\nname:           hw-fingertree\nversion:        0.1.1.0\nsynopsis:       Generic finger-tree structure, with example instances\ndescription:    A general sequence representation with arbitrary\n                annotations, for use as a base for implementations of\n                various collection types, with examples, as described\n                in section 4 of\n                .\n                * Ralf Hinze and Ross Paterson,\n                \\\"Finger trees: a simple general-purpose data structure\\\",\n                /Journal of Functional Programming/ 16:2 (2006) pp 197-217.\n                <http://staff.city.ac.uk/~ross/papers/FingerTree.html>\n                .\n                For a tuned sequence type, see @Data.Sequence@ in the\n                @containers@ package, which is a specialization of\n                this structure.\ncategory:       Data Structures\nhomepage:       https://github.com/haskell-works/hw-fingertree#readme\nbug-reports:    https://github.com/haskell-works/hw-fingertree/issues\nmaintainer:     John Ky <newhoggy@gmail.com>\ncopyright:      (c) 2017-2019 John Ky\n                (c) 2006 Ross Paterson, Ralf Hinze,\nlicense:        BSD-3-Clause\nlicense-file:   LICENSE\nbuild-type:     Simple\n\ncommon base                       { build-depends: base                       >= 4          && < 5      }\n\ncommon deepseq                    { build-depends: deepseq                                              }\ncommon hedgehog                   { build-depends: hedgehog                                             }\ncommon hspec                      { build-depends: hspec                                                }\ncommon hw-fingertree              { build-depends: hw-fingertree                                        }\ncommon hw-hspec-hedgehog          { build-depends: hw-hspec-hedgehog                                    }\ncommon hw-prim                    { build-depends: hw-prim                    >= 0.6.2.25   && < 0.7    }\n\ncommon config\n  default-language: Haskell2010\n\nsource-repository head\n  type: git\n  location: https://github.com/haskell-works/hw-fingertree\n\nlibrary\n  import:   base, config\n          , deepseq\n          , hw-prim\n  hs-source-dirs:     src\n  other-modules:      Paths_hw_fingertree\n  autogen-modules:    Paths_hw_fingertree\n  exposed-modules:\n    HaskellWorks.Data.FingerTree\n    HaskellWorks.Data.IntervalMap.FingerTree\n    HaskellWorks.Data.PriorityQueue.FingerTree\n\ntest-suite hw-fingertree-tests\n  import:   base, config\n          , deepseq\n          , hedgehog\n          , hspec\n          , hw-hspec-hedgehog\n  build-depends:      hw-fingertree\n  type:               exitcode-stdio-1.0\n  main-is:            Spec.hs\n  hs-source-dirs:     tests\n  build-tools:        hspec-discover\n  autogen-modules:    Paths_hw_fingertree\n  other-modules:\n    HaskellWorks.Data.FingerTree.Gen\n    HaskellWorks.Data.FingerTreeSpec\n    Paths_hw_fingertree\n";
  }