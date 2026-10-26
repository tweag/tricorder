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
      identifier = { name = "dependent-map"; version = "0.4.0.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Obsidian Systems, LLC <maintainer@obsidian.systems>";
      author = "James Cook <mokus@deepbondi.net>";
      homepage = "https://github.com/obsidiansystems/dependent-map";
      url = "";
      synopsis = "Dependent finite maps (partial dependent products)";
      description = "Provides a type called @DMap@ which generalizes\n@Data.Map.Map@, allowing keys to specify the type\nof value that can be associated with them.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."dependent-sum" or (errorHandler.buildDepError "dependent-sum"))
          (hsPkgs."constraints-extras" or (errorHandler.buildDepError "constraints-extras"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/dependent-map-0.4.0.1.tar.gz";
      sha256 = "4da32e3c57a8afb1e61664bac9e79c3b410e31e839ffd78e0c7716be415a2cde";
    });
  }) // {
    package-description-override = "cabal-version:          3.0\nname:                   dependent-map\nversion:                0.4.0.1\nstability:              provisional\n\nbuild-type:             Simple\n\nauthor:                 James Cook <mokus@deepbondi.net>\nmaintainer:             Obsidian Systems, LLC <maintainer@obsidian.systems>\nlicense:                BSD-3-Clause\nlicense-file:           LICENSE\nhomepage:               https://github.com/obsidiansystems/dependent-map\n\ncategory:               Data, Dependent Types\nsynopsis:               Dependent finite maps (partial dependent products)\ndescription:            Provides a type called @DMap@ which generalizes\n                        @Data.Map.Map@, allowing keys to specify the type\n                        of value that can be associated with them.\n\nextra-source-files: ChangeLog.md\n                    README.md\n\ntested-with:            GHC == 8.4.4,\n                        GHC == 8.6.5,\n                        GHC == 8.8.4,\n                        GHC == 8.10.7,\n                        GHC == 9.0.2,\n                        GHC == 9.2.8,\n                        GHC == 9.4.8,\n                        GHC == 9.6.5,\n                        GHC == 9.8.2,\n                        GHC == 9.10.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/obsidiansystems/dependent-map\n\nLibrary\n  hs-source-dirs:       src\n  ghc-options:          -fwarn-unused-imports -fwarn-unused-binds\n  exposed-modules:      Data.Dependent.Map,\n                        Data.Dependent.Map.Lens,\n                        Data.Dependent.Map.Internal\n  other-modules:        Data.Dependent.Map.PtrEquality\n  build-depends:        base >= 4.11 && < 5,\n                        containers >= 0.5.7.1 && <0.8,\n                        dependent-sum >= 0.6.1 && < 0.8,\n                        constraints-extras >= 0.2.3.0 && < 0.5\n  default-language:     Haskell2010\n";
  }