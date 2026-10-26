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
      identifier = { name = "data-default-class"; version = "0.2.0.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2013 Lukas Mai";
      maintainer = "<lukasmai.403+hackage@gmail.com>";
      author = "Lukas Mai";
      homepage = "";
      url = "";
      synopsis = "A class for types with a default value (compatibility shim)";
      description = "This module re-exports the 'Default' class from \"Data.Default\", for\ncompatibility with older code.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/data-default-class-0.2.0.0.tar.gz";
      sha256 = "0ae530c4fb0bd6c8a8ba399429ccd9c75f9c7696049117178f4ceeb2bd08d5b4";
    });
  }) // {
    package-description-override = "cabal-version:   3.0\nname:            data-default-class\nversion:         0.2.0.0\ncategory:        Data\nsynopsis:        A class for types with a default value (compatibility shim)\ndescription:\n    This module re-exports the 'Default' class from \"Data.Default\", for\n    compatibility with older code.\nbuild-type:      Simple\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE\ncopyright:       (c) 2013 Lukas Mai\nauthor:          Lukas Mai\nmaintainer:      <lukasmai.403+hackage@gmail.com>\n\nsource-repository head\n    type: git\n    location: https://github.com/mauke/data-default\n    branch: flare\n\nlibrary\n    build-depends:     data-default ^>=0.8\n    exposed-modules:   Data.Default.Class\n    default-language:  Haskell98\n";
  }