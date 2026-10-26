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
      identifier = { name = "conduit-extra"; version = "1.3.8"; };
      license = "MIT";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman";
      homepage = "http://github.com/snoyberg/conduit";
      url = "";
      synopsis = "Batteries included conduit: adapters for common libraries.";
      description = "The conduit package itself maintains relative small dependencies. The purpose of this package is to collect commonly used utility functions wrapping other library dependencies, without depending on heavier-weight dependencies. The basic idea is that this package should only depend on haskell-platform packages and conduit.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."streaming-commons" or (errorHandler.buildDepError "streaming-commons"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
          (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
            (hsPkgs."conduit-extra" or (errorHandler.buildDepError "conduit-extra"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."streaming-commons" or (errorHandler.buildDepError "streaming-commons"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "blaze" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
            (hsPkgs."conduit-extra" or (errorHandler.buildDepError "conduit-extra"))
            (hsPkgs."gauge" or (errorHandler.buildDepError "gauge"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/conduit-extra-1.3.8.tar.gz";
      sha256 = "491f3e8e9408f5d10ff8d02bf4d0edb11821e2537e7c22edbd6d64bf91388222";
    });
  }) // {
    package-description-override = "Cabal-version:       >=1.10\r\nName:                conduit-extra\r\nVersion:             1.3.8\r\nx-revision: 1\r\nSynopsis:            Batteries included conduit: adapters for common libraries.\r\nDescription:\r\n    The conduit package itself maintains relative small dependencies. The purpose of this package is to collect commonly used utility functions wrapping other library dependencies, without depending on heavier-weight dependencies. The basic idea is that this package should only depend on haskell-platform packages and conduit.\r\nLicense:             MIT\r\nLicense-file:        LICENSE\r\nAuthor:              Michael Snoyman\r\nMaintainer:          michael@snoyman.com\r\nCategory:            Data, Conduit\r\nBuild-type:          Simple\r\nHomepage:            http://github.com/snoyberg/conduit\r\nextra-source-files:\r\n    test/random\r\n    test/filesystem/*.txt\r\n    test/filesystem/bin/*.txt\r\n    ChangeLog.md\r\n    README.md\r\n\r\nLibrary\r\n  default-language:    Haskell2010\r\n  Exposed-modules:     Data.Conduit.Attoparsec\r\n                       Data.Conduit.Binary\r\n                       Data.Conduit.ByteString.Builder\r\n                       Data.Conduit.Filesystem\r\n                       Data.Conduit.Foldl\r\n                       Data.Conduit.Lazy\r\n                       Data.Conduit.Network\r\n                       Data.Conduit.Network.UDP\r\n                       Data.Conduit.Network.Unix\r\n                       Data.Conduit.Process\r\n                       Data.Conduit.Process.Typed\r\n                       Data.Conduit.Text\r\n                       Data.Conduit.Zlib\r\n\r\n  if arch(x86_64) || arch(i386)\r\n      -- These architectures are able to perform unaligned memory accesses\r\n      cpp-options: -DALLOW_UNALIGNED_ACCESS\r\n\r\n  Build-depends:       base                     >= 4.14         && < 5\r\n                     , conduit                  >= 1.3          && < 1.4\r\n\r\n                     , bytestring               >= 0.10.2\r\n                     , text\r\n                     , transformers\r\n\r\n                     , async\r\n                     , attoparsec               >= 0.10\r\n                     , directory\r\n                     , filepath\r\n                     , network                  >= 2.3\r\n                     , primitive                >= 0.5\r\n                     , process\r\n                     , resourcet                >= 1.1\r\n                     , stm\r\n                     , streaming-commons        >= 0.2.3.0\r\n                     , unliftio-core\r\n                     , typed-process            >= 0.2.6\r\n\r\n  ghc-options:     -Wall\r\n\r\ntest-suite test\r\n    hs-source-dirs: test\r\n    default-language: Haskell2010\r\n    main-is: Spec.hs\r\n    type: exitcode-stdio-1.0\r\n    ghc-options:   -threaded\r\n    cpp-options:   -DTEST\r\n    build-depends:   conduit\r\n                   , conduit-extra\r\n                   , base\r\n                   , hspec >= 1.3\r\n\r\n                   , async\r\n                   , attoparsec\r\n                   , bytestring\r\n                   , exceptions\r\n                   , process\r\n                   , resourcet\r\n                   , QuickCheck\r\n                   , stm\r\n                   , streaming-commons\r\n                   , text\r\n                   , transformers\r\n                   , transformers-base\r\n                   , directory\r\n                   , filepath\r\n    build-tool-depends: hspec-discover:hspec-discover\r\n    ghc-options:     -Wall\r\n    if os(windows)\r\n        cpp-options: -DWINDOWS\r\n    other-modules:   Data.Conduit.AttoparsecSpec\r\n                     Data.Conduit.BinarySpec\r\n                     Data.Conduit.ByteString.BuilderSpec\r\n                     Data.Conduit.ExtraSpec\r\n                     Data.Conduit.FilesystemSpec\r\n                     Data.Conduit.LazySpec\r\n                     Data.Conduit.NetworkSpec\r\n                     Data.Conduit.ProcessSpec\r\n                     Data.Conduit.Process.TypedSpec\r\n                     Data.Conduit.TextSpec\r\n                     Data.Conduit.ZlibSpec\r\n\r\nbenchmark blaze\r\n    default-language: Haskell2010\r\n    type:           exitcode-stdio-1.0\r\n    hs-source-dirs: bench\r\n    build-depends:  base\r\n                  , conduit\r\n                  , conduit-extra\r\n                  , gauge\r\n                  , bytestring\r\n                  , transformers\r\n    main-is:        blaze.hs\r\n    ghc-options:    -Wall -O2 -rtsopts\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: git://github.com/snoyberg/conduit.git\r\n";
  }