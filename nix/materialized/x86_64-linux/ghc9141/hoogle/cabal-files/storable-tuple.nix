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
    flags = { splitbase = true; };
    package = {
      specVersion = "2.2";
      identifier = { name = "storable-tuple"; version = "0.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Henning Thielemann <storable@henning-thielemann.de>";
      author = "Henning Thielemann <storable@henning-thielemann.de>";
      homepage = "http://code.haskell.org/~thielema/storable-tuple/";
      url = "";
      synopsis = "Storable instance for pairs and triples";
      description = "Provides a Storable instance for pair and triple\nwhich should be binary compatible with C99 and C++.\nThe only purpose of this package is to provide a standard location\nfor this instance so that other packages needing this instance\ncan play nicely together.\nNote however, that the original purpose of the @Storable@ class\nwas the transfer of primitive types between Haskell and foreign code.\nThis purpose was already extended by HSC,\nwhich creates @Storable@ instances for records from C header files.\nNonetheless,\n@Storable@ instances for tuples were omitted from @base@ by intention.\nInstead of using the orphan instances from this package,\nyou may instead use the custom class or the wrapper type\nfrom the module @Foreign.Storable.Record.Tuple@\nfrom the package @storable-record@.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."storable-record" or (errorHandler.buildDepError "storable-record"))
          (hsPkgs."utility-ht" or (errorHandler.buildDepError "utility-ht"))
          (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"))
        ] ++ (if flags.splitbase
          then [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ]
          else [
            (hsPkgs."special-functors" or (errorHandler.buildDepError "special-functors"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
          ]);
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/storable-tuple-0.1.tar.gz";
      sha256 = "034b4fa44239d60326af52fecde604ba65ef1f75cfd5cef1ded2079a3b86593c";
    });
  }) // {
    package-description-override = "Cabal-Version: 2.2\nName:         storable-tuple\nVersion:      0.1\nCategory:     Data, Foreign\nSynopsis:     Storable instance for pairs and triples\nDescription:\n  Provides a Storable instance for pair and triple\n  which should be binary compatible with C99 and C++.\n\n  The only purpose of this package is to provide a standard location\n  for this instance so that other packages needing this instance\n  can play nicely together.\n\n  Note however, that the original purpose of the @Storable@ class\n  was the transfer of primitive types between Haskell and foreign code.\n  This purpose was already extended by HSC,\n  which creates @Storable@ instances for records from C header files.\n  Nonetheless,\n  @Storable@ instances for tuples were omitted from @base@ by intention.\n  Instead of using the orphan instances from this package,\n  you may instead use the custom class or the wrapper type\n  from the module @Foreign.Storable.Record.Tuple@\n  from the package @storable-record@.\nLicense:             BSD-3-Clause\nLicense-file:        LICENSE\nAuthor:              Henning Thielemann <storable@henning-thielemann.de>\nMaintainer:          Henning Thielemann <storable@henning-thielemann.de>\nHomepage:            http://code.haskell.org/~thielema/storable-tuple/\nStability:           Experimental\nBuild-Type:          Simple\nTested-With:         GHC==6.8.2, GHC==8.0.1\n\nExtra-Source-Files:\n  Changes.md\n\nSource-Repository head\n  Type:     darcs\n  Location: http://code.haskell.org/~thielema/storable-tuple/\n\nSource-Repository this\n  Type:     darcs\n  Location: http://code.haskell.org/~thielema/storable-tuple/\n  Tag:      0.1\n\nFlag splitBase\n  Description: Choose the new smaller, split-up base package.\n\nLibrary\n  Build-Depends:\n    storable-record >=0.0.5 && <0.1,\n    utility-ht >=0.0.1 && <0.1,\n    base-orphans >= 0.5 && <1\n  If flag(splitBase)\n    Build-Depends: base >=3 && <5\n  Else\n    Build-Depends:\n      special-functors >= 1.0 && <1.1,\n      base >= 1.0 && < 2\n\n  Default-Language:    Haskell98\n  GHC-Options:         -Wall -fno-warn-orphans\n  Hs-Source-Dirs:      src\n\n  Exposed-Modules:\n    Foreign.Storable.Tuple\n";
  }