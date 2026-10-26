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
      specVersion = "1.12";
      identifier = { name = "th-lift"; version = "0.8.7"; };
      license = "BSD-3-Clause";
      copyright = "© 2006 Ian Lynagh, © 2010-2019 Mathieu Boespflug, © 2019 Ryan Scott";
      maintainer = "Ryan Scott <ryan.gl.scott@gmail.com>";
      author = "Ian Lynagh";
      homepage = "http://github.com/RyanGlScott/th-lift";
      url = "";
      synopsis = "Derive Template Haskell's Lift class for datatypes.";
      description = "Derive Template Haskell's @Lift@ class for datatypes using @TemplateHaskell@.\nThe functionality in this package has largely been subsumed by the\n@DeriveLift@ language extension, which is available in GHC 8.0 and later\nversions. As such, this package is only useful as a way to backport bugfixes\nto @DeriveLift@ in later GHC versions back to older GHCs.\n\nThe following libraries are related:\n\n* The <https://hackage.haskell.org/package/th-orphans th-orphans> package\nprovides instances for @template-haskell@ syntax types.\n\n* The <http://hackage.haskell.org/package/th-lift-instances th-lift-instances>\npackage provides @Lift@ instances for types in @base@, @text@,\n@bytestring@, @vector@, etc. Some of these instances are only provided for\nold versions of their respective libraries, as the same @Lift@ instances\nare also present upstream on newer versions.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."th-lift" or (errorHandler.buildDepError "th-lift"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/th-lift-0.8.7.tar.gz";
      sha256 = "dd157c626cb0b0fa71adac3690305aeafccf503583fce387628b210fadc69806";
    });
  }) // {
    package-description-override = "Name:               th-lift\nVersion:            0.8.7\nCabal-Version:      1.12\nLicense:            BSD3\nLicense-Files:      COPYING, BSD3, GPL-2\nCopyright:          © 2006 Ian Lynagh, © 2010-2019 Mathieu Boespflug, © 2019 Ryan Scott\nAuthor:             Ian Lynagh\nMaintainer:         Ryan Scott <ryan.gl.scott@gmail.com>\nHomepage:           http://github.com/RyanGlScott/th-lift\nSynopsis:           Derive Template Haskell's Lift class for datatypes.\nDescription:\n  Derive Template Haskell's @Lift@ class for datatypes using @TemplateHaskell@.\n  The functionality in this package has largely been subsumed by the\n  @DeriveLift@ language extension, which is available in GHC 8.0 and later\n  versions. As such, this package is only useful as a way to backport bugfixes\n  to @DeriveLift@ in later GHC versions back to older GHCs.\n  .\n  The following libraries are related:\n  .\n  * The <https://hackage.haskell.org/package/th-orphans th-orphans> package\n    provides instances for @template-haskell@ syntax types.\n  .\n  * The <http://hackage.haskell.org/package/th-lift-instances th-lift-instances>\n    package provides @Lift@ instances for types in @base@, @text@,\n    @bytestring@, @vector@, etc. Some of these instances are only provided for\n    old versions of their respective libraries, as the same @Lift@ instances\n    are also present upstream on newer versions.\nCategory:           Language\nTested-With:        GHC==8.0.2, GHC==8.2.2, GHC==8.4.4, GHC==8.6.5, GHC==8.8.4, GHC==8.10.7, GHC==9.0.2, GHC==9.2.8, GHC==9.4.8, GHC==9.6.6, GHC==9.8.4, GHC==9.10.3, GHC==9.12.2, GHC==9.14.1\nbuild-type:         Simple\nExtra-source-files: CHANGELOG.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/RyanGlScott/th-lift\n\nLibrary\n  Default-Language: Haskell2010\n  Exposed-modules:  Language.Haskell.TH.Lift\n                    Language.Haskell.TH.Lift.Internal\n  Other-Extensions: CPP,  MagicHash, TypeSynonymInstances, FlexibleInstances, TemplateHaskellQuotes\n  Hs-Source-Dirs:   src\n  Build-Depends:    base             >= 4.9  && < 5,\n                    th-abstraction   >= 0.5  && < 0.8,\n                    template-haskell >= 2.11 && < 2.25\n  ghc-options:      -Wall\n\nTest-Suite test\n  Default-Language: Haskell2010\n  Type:             exitcode-stdio-1.0\n  Main-Is:          Test.hs\n  Hs-Source-Dirs:   t\n  other-modules:    Foo\n  ghc-options:      -Wall\n  if impl(ghc >= 9.0)\n    ghc-options:    -fenable-th-splice-warnings\n  Build-Depends:    base,\n                    th-lift,\n                    template-haskell\n\n";
  }