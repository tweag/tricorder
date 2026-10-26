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
      identifier = { name = "table-layout"; version = "1.0.0.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "muesli4@gmail.com";
      author = "Moritz Bruder";
      homepage = "https://github.com/muesli4/table-layout";
      url = "";
      synopsis = "Format tabular data as grid or table.";
      description = "`table-layout` is a library for text-based table layout and cell formatting\nwith the following features:\n\n* Set a policy for each column to determine the width.\n\n* Position content in a column at a certain position.\n\n* Align content in a column at a character occurence.\n\n* Highlight trimmed content with cut marks.\n\n* Draw fancy tables with optional headers and user styles.\n\n* Automatically justify text and create multi-line table cells.\n\nThe module `Text.Layout.Table` contains everything that is required.\nHowever, all of the intermediate functionality is also exposed which makes\nit easy to create something completely new. A small tutorial is provided in\nthe `README.md` file.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."data-default-class" or (errorHandler.buildDepError "data-default-class"))
          (hsPkgs."doclayout" or (errorHandler.buildDepError "doclayout"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      exes = {
        "table-layout-test-styles" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."data-default-class" or (errorHandler.buildDepError "data-default-class"))
            (hsPkgs."doclayout" or (errorHandler.buildDepError "doclayout"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
      tests = {
        "table-layout-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."data-default-class" or (errorHandler.buildDepError "data-default-class"))
            (hsPkgs."doclayout" or (errorHandler.buildDepError "doclayout"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/table-layout-1.0.0.2.tar.gz";
      sha256 = "3895f5b162c45cd934970c322e7eab2a65104e25fcec37462760bb5ffe0cae35";
    });
  }) // {
    package-description-override = "name:                table-layout\n\n-- The package version.  See the Haskell package versioning policy (PVP) \n-- for standards guiding when and how versions should be incremented.\n-- http://www.haskell.org/haskellwiki/Package_versioning_policy\n-- PVP summary:      +-+------- breaking API changes\n--                   | | +----- non-breaking API additions\n--                   | | | +--- code changes with no API change\nversion:             1.0.0.2\n\nsynopsis:            Format tabular data as grid or table.\n\ndescription:         \n    `table-layout` is a library for text-based table layout and cell formatting\n    with the following features:\n    .\n    * Set a policy for each column to determine the width.\n    .\n    * Position content in a column at a certain position.\n    .\n    * Align content in a column at a character occurence.\n    .\n    * Highlight trimmed content with cut marks.\n    .\n    * Draw fancy tables with optional headers and user styles.\n    .\n    * Automatically justify text and create multi-line table cells.\n    .\n    The module `Text.Layout.Table` contains everything that is required.\n    However, all of the intermediate functionality is also exposed which makes\n    it easy to create something completely new. A small tutorial is provided in\n    the `README.md` file.\n\n-- URL for the project homepage or repository.\nhomepage:              https://github.com/muesli4/table-layout\nlicense:               BSD3\nlicense-file:          LICENSE\nauthor:                Moritz Bruder\nmaintainer:            muesli4@gmail.com\ncategory:              Text\nbuild-type:            Simple\n-- Extra files to be distributed with the package, such as examples or a \n-- README.\nextra-source-files:    README.md, CHANGELOG.md\n\n-- Constraint on the version of Cabal needed to build this package.\ncabal-version:         >=1.10\n\nsource-repository head\n    type:              git\n    location:          git://github.com/muesli4/table-layout.git\n\n\nlibrary\n  exposed-modules:     Text.Layout.Table,\n                       Text.Layout.Table.Cell,\n                       Text.Layout.Table.Cell.Formatted,\n                       Text.Layout.Table.Cell.WideString,\n                       Text.Layout.Table.Justify,\n                       Text.Layout.Table.LineStyle,\n                       Text.Layout.Table.Style,\n                       Text.Layout.Table.Vertical,\n                       Text.Layout.Table.StringBuilder,\n                       Text.Layout.Table.Pandoc,\n\n\n                       -- Will be moved into another package in the future.\n                       Text.Layout.Table.Primitives.AlignInfo,\n                       Text.Layout.Table.Primitives.Basic,\n                       Text.Layout.Table.Primitives.CellMod,\n                       Text.Layout.Table.Primitives.ColumnModifier,\n                       Text.Layout.Table.Primitives.Header,\n                       Text.Layout.Table.Primitives.Table,\n                       Text.Layout.Table.Spec.AlignSpec,\n                       Text.Layout.Table.Spec.ColSpec,\n                       Text.Layout.Table.Spec.CutMark,\n                       Text.Layout.Table.Spec.HeaderColSpec,\n                       Text.Layout.Table.Spec.HeaderSpec,\n                       Text.Layout.Table.Spec.LenSpec,\n                       Text.Layout.Table.Spec.OccSpec,\n                       Text.Layout.Table.Spec.Position,\n                       Text.Layout.Table.Spec.RowGroup,\n                       Text.Layout.Table.Spec.TableSpec,\n                       Text.Layout.Table.Spec.Util\n  other-modules:\n\n  \n  -- LANGUAGE extensions used by modules in this package.\n  other-extensions:    RecordWildCards,\n                       EmptyDataDecls,\n                       FlexibleInstances,\n                       PatternSynonyms,\n                       MultiWayIf\n  \n  -- Other library packages from which modules are imported.\n  build-depends:       base >=4.9 && <5,\n                       data-default-class >=0.1.2 && < 0.3,\n                       doclayout >=0.3 && <0.6,\n                       text\n\n  hs-source-dirs:      src\n  \n  -- Base language which the package is written in.\n  default-language:    Haskell2010\n\nexecutable table-layout-test-styles\n  main-is:             Test.hs\n  build-depends:       base >=4.9 && <5,\n                       data-default-class >=0.1.2 && < 0.3,\n                       doclayout >=0.3 && <0.6,\n                       text\n  hs-source-dirs:      src\n  other-modules:       Text.Layout.Table,\n                       Text.Layout.Table.Cell,\n                       Text.Layout.Table.Cell.Formatted,\n                       Text.Layout.Table.Cell.WideString,\n                       Text.Layout.Table.Justify,\n                       Text.Layout.Table.LineStyle,\n                       Text.Layout.Table.Style,\n                       Text.Layout.Table.Vertical\n\n                       Text.Layout.Table.Primitives.AlignInfo,\n                       Text.Layout.Table.Primitives.Basic,\n                       Text.Layout.Table.Primitives.CellMod,\n                       Text.Layout.Table.Primitives.ColumnModifier,\n                       Text.Layout.Table.Primitives.Header,\n                       Text.Layout.Table.Primitives.Table,\n                       Text.Layout.Table.StringBuilder,\n\n                       Text.Layout.Table.Spec.AlignSpec,\n                       Text.Layout.Table.Spec.ColSpec,\n                       Text.Layout.Table.Spec.CutMark,\n                       Text.Layout.Table.Spec.HeaderColSpec,\n                       Text.Layout.Table.Spec.HeaderSpec,\n                       Text.Layout.Table.Spec.LenSpec,\n                       Text.Layout.Table.Spec.OccSpec,\n                       Text.Layout.Table.Spec.Position,\n                       Text.Layout.Table.Spec.RowGroup,\n                       Text.Layout.Table.Spec.TableSpec,\n                       Text.Layout.Table.Spec.Util\n\n  default-language:    Haskell2010\n\ntest-suite table-layout-tests\n  type:                exitcode-stdio-1.0\n  hs-source-dirs:      test-suite, src\n  main-is:             Spec.hs\n  build-depends:       base >=4.9 && <5,\n                       QuickCheck >=2.8 && < 2.16,\n                       HUnit >=1.3,\n                       data-default-class >=0.1.2 && < 0.3,\n                       doclayout >=0.3 && <0.6,\n                       text,\n                       hspec\n\n  other-modules:       TestSpec,\n\n                       Text.Layout.Table\n\n                       Text.Layout.Table.Cell,\n                       Text.Layout.Table.Cell.Formatted,\n                       Text.Layout.Table.Cell.WideString,\n                       Text.Layout.Table.Justify,\n                       Text.Layout.Table.LineStyle,\n                       Text.Layout.Table.Style,\n                       Text.Layout.Table.Vertical\n\n                       Text.Layout.Table.Primitives.AlignInfo,\n                       Text.Layout.Table.Primitives.Basic,\n                       Text.Layout.Table.Primitives.CellMod,\n                       Text.Layout.Table.Primitives.ColumnModifier,\n                       Text.Layout.Table.Primitives.Header,\n                       Text.Layout.Table.Primitives.Table,\n                       Text.Layout.Table.StringBuilder,\n\n                       Text.Layout.Table.Spec.AlignSpec,\n                       Text.Layout.Table.Spec.ColSpec,\n                       Text.Layout.Table.Spec.CutMark,\n                       Text.Layout.Table.Spec.HeaderColSpec,\n                       Text.Layout.Table.Spec.HeaderSpec,\n                       Text.Layout.Table.Spec.LenSpec,\n                       Text.Layout.Table.Spec.OccSpec,\n                       Text.Layout.Table.Spec.Position,\n                       Text.Layout.Table.Spec.RowGroup,\n                       Text.Layout.Table.Spec.TableSpec,\n                       Text.Layout.Table.Spec.Util\n\n  default-language:    Haskell2010\n";
  }