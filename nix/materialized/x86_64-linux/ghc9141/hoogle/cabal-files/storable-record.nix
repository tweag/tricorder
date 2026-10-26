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
    flags = { splitbase = true; buildtests = false; };
    package = {
      specVersion = "2.2";
      identifier = { name = "storable-record"; version = "0.0.7"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Henning Thielemann <storable@henning-thielemann.de>";
      author = "Henning Thielemann <storable@henning-thielemann.de>";
      homepage = "http://code.haskell.org/~thielema/storable-record/";
      url = "";
      synopsis = "Elegant definition of Storable instances for records";
      description = "With this package\nyou can build a Storable instance of a record type\nfrom Storable instances of its elements in an elegant way.\nIt does not do any magic,\njust a bit arithmetic to compute the right offsets,\nthat would be otherwise done manually\nor by a preprocessor like C2HS.\nI cannot promise that the generated memory layout\nis compatible with that of a corresponding C struct.\nHowever, the module generates the smallest layout\nthat is possible with respect to the alignment of the record elements.\nIf you encounter, that a record does not have a compatible layout,\nwe should fix that.\nBut also without C compatibility this package is useful\ne.g. in connection with StorableVector.\n\nWe provide Storable instance support for several cases:\n\n* If you wrap a type in a @newtype@,\nthen you can lift its 'Storable' instance to that @newtype@\nwith the module \"Foreign.Storable.Newtype\".\nThis way you do not need the @GeneralizedNewtypeDeriving@ feature of GHC.\n\n* If you have a type that is an instance of 'Traversable',\nyou can use that feature for implementation of 'Storable' methods.\nThe module \"Foreign.Storable.Traversable\"\nallows manipulation of the portion of your type,\nthat is accessible by 'Traversable' methods.\nFor instance with the type\n@data T a = Cons Int [a]@\nand an according 'Traversable' implementation,\nyou can load and store the elements of the contained list.\nThis may be part of a 'Storable' implementation of the whole type.\n\n* If you have a record containing elements of various types,\nthen you need module \"Foreign.Storable.Record\".\n\nNote however that the Storable instances\ndefined with this package are quite slow in (up to) GHC-6.12.1.\nI'm afraid this is due to incomplete inlining,\nbut we have still to investigate the problem.\n\nFor examples see packages @storable-tuple@ and @sample-frame@.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
          (hsPkgs."utility-ht" or (errorHandler.buildDepError "utility-ht"))
        ] ++ (if flags.splitbase
          then [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ]
          else [
            (hsPkgs."special-functors" or (errorHandler.buildDepError "special-functors"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
          ]);
        buildable = true;
      };
      exes = {
        "storable-record-speed" = {
          depends = pkgs.lib.optionals (flags.buildtests) [
            (hsPkgs."storablevector" or (errorHandler.buildDepError "storablevector"))
            (hsPkgs."timeit" or (errorHandler.buildDepError "timeit"))
          ];
          buildable = if flags.buildtests then true else false;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/storable-record-0.0.7.tar.gz";
      sha256 = "bec546c894d39182af50415743af226456a5f79da281d1a3c0b7db11362a2eb0";
    });
  }) // {
    package-description-override = "Cabal-Version: 2.2\nName:         storable-record\nVersion:      0.0.7\nCategory:     Data, Foreign\nSynopsis:     Elegant definition of Storable instances for records\nDescription:\n  With this package\n  you can build a Storable instance of a record type\n  from Storable instances of its elements in an elegant way.\n  It does not do any magic,\n  just a bit arithmetic to compute the right offsets,\n  that would be otherwise done manually\n  or by a preprocessor like C2HS.\n  I cannot promise that the generated memory layout\n  is compatible with that of a corresponding C struct.\n  However, the module generates the smallest layout\n  that is possible with respect to the alignment of the record elements.\n  If you encounter, that a record does not have a compatible layout,\n  we should fix that.\n  But also without C compatibility this package is useful\n  e.g. in connection with StorableVector.\n  .\n  We provide Storable instance support for several cases:\n  .\n  * If you wrap a type in a @newtype@,\n    then you can lift its 'Storable' instance to that @newtype@\n    with the module \"Foreign.Storable.Newtype\".\n    This way you do not need the @GeneralizedNewtypeDeriving@ feature of GHC.\n  .\n  * If you have a type that is an instance of 'Traversable',\n    you can use that feature for implementation of 'Storable' methods.\n    The module \"Foreign.Storable.Traversable\"\n    allows manipulation of the portion of your type,\n    that is accessible by 'Traversable' methods.\n    For instance with the type\n    @data T a = Cons Int [a]@\n    and an according 'Traversable' implementation,\n    you can load and store the elements of the contained list.\n    This may be part of a 'Storable' implementation of the whole type.\n  .\n  * If you have a record containing elements of various types,\n    then you need module \"Foreign.Storable.Record\".\n  .\n  Note however that the Storable instances\n  defined with this package are quite slow in (up to) GHC-6.12.1.\n  I'm afraid this is due to incomplete inlining,\n  but we have still to investigate the problem.\n  .\n  For examples see packages @storable-tuple@ and @sample-frame@.\nLicense:             BSD-3-Clause\nLicense-file:        LICENSE\nAuthor:              Henning Thielemann <storable@henning-thielemann.de>\nMaintainer:          Henning Thielemann <storable@henning-thielemann.de>\nHomepage:            http://code.haskell.org/~thielema/storable-record/\nStability:           Experimental\nBuild-Type:          Simple\nTested-With:         GHC==6.8.2, GHC==6.10.4, GHC==6.12.1, GHC==8.0.1\n\nSource-Repository head\n  Type:     darcs\n  Location: http://code.haskell.org/~thielema/storable-record/\n\nSource-Repository this\n  Type:     darcs\n  Location: http://code.haskell.org/~thielema/storable-record/\n  Tag:      0.0.7\n\nFlag splitBase\n  description: Choose the new smaller, split-up base package.\n\nFlag buildTests\n  description: Build speed test\n  default:     False\n\nLibrary\n  Build-Depends:\n    QuickCheck >=2 && <3,\n    transformers >=0.2 && <0.7,\n    semigroups >=0.1 && <1.0,\n    utility-ht >=0.0.14 && <0.1\n  If flag(splitBase)\n    Build-Depends:\n      base >= 3 && < 6\n  Else\n    Build-Depends:\n      special-functors >= 1.0 && <1.1,\n      base >= 1.0 && < 2\n\n  Default-Language:    Haskell98\n  GHC-Options:         -Wall\n  Hs-Source-Dirs:      src\n\n  Exposed-Modules:\n    Foreign.Storable.Record\n    Foreign.Storable.Record.Tuple\n    Foreign.Storable.Newtype\n    Foreign.Storable.Traversable\n    Foreign.Storable.FixedArray\n  Other-Modules:\n    Foreign.Storable.RecordMinimalSize\n    Foreign.Storable.RecordReaderPtr\n    Foreign.Storable.TraversableUnequalSizes\n\nExecutable storable-record-speed\n  If flag(buildTests)\n    Build-Depends:\n      storablevector >=0.2.7 && <0.3,\n      timeit >=1.0 && <1.1\n  Else\n    Buildable: False\n\n  Default-Language:    Haskell98\n  GHC-Options:         -Wall\n  Hs-Source-Dirs:      src\n  Main-Is:             SpeedTest.hs\n";
  }