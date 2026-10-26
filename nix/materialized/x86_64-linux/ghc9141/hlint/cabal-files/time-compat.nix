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
      identifier = { name = "time-compat"; version = "1.9.9"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Ashley Yakeley";
      homepage = "https://github.com/haskellari/time-compat";
      url = "";
      synopsis = "Compatibility package for time";
      description = "This packages tries to compat as much of @time@ features as possible.\n\n/TODO:/\n\n* Difference type @ParseTime@ and @FormatTime@ instances are missing.\n\n* Formatting varies depending on underlying @time@ version\n\n* @dayFractionToTimeOfDay@ on extreme values";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
        ];
        buildable = true;
      };
      tests = {
        "instances" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          ];
          buildable = true;
        };
        "test-main" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          ] ++ pkgs.lib.optionals (!(compiler.isGhc && compiler.version.ge "8.0")) [
            (hsPkgs."fail" or (errorHandler.buildDepError "fail"))
            (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
          ];
          buildable = if !(compiler.isGhc && compiler.version.ge "7.4")
            then false
            else true;
        };
        "test-template" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/time-compat-1.9.9.tar.gz";
      sha256 = "90fadded53cf9c15855eebf809e9536af8f85d00e32b82f7c8b506d2fadf7c25";
    });
  }) // {
    package-description-override = "cabal-version:      1.12\r\nname:               time-compat\r\nversion:            1.9.9\r\nx-revision:         1\r\nsynopsis:           Compatibility package for time\r\ndescription:\r\n  This packages tries to compat as much of @time@ features as possible.\r\n  .\r\n  /TODO:/\r\n  .\r\n  * Difference type @ParseTime@ and @FormatTime@ instances are missing.\r\n  .\r\n  * Formatting varies depending on underlying @time@ version\r\n  .\r\n  * @dayFractionToTimeOfDay@ on extreme values\r\n\r\ncategory:           Time, Compatibility\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\r\nauthor:             Ashley Yakeley\r\nhomepage:           https://github.com/haskellari/time-compat\r\nbug-reports:        https://github.com/haskellari/time-compat/issues\r\nbuild-type:         Simple\r\nextra-source-files: CHANGELOG.md\r\ntested-with:\r\n  GHC ==8.6.5\r\n   || ==8.8.4\r\n   || ==8.10.7\r\n   || ==9.0.2\r\n   || ==9.2.8\r\n   || ==9.4.8\r\n   || ==9.6.7\r\n   || ==9.8.4\r\n   || ==9.10.2\r\n   || ==9.12.2\r\n   || ==9.14.1\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskellari/time-compat.git\r\n\r\nlibrary\r\n  default-language:   Haskell2010\r\n  hs-source-dirs:     src\r\n  other-extensions:   CPP\r\n  default-extensions: Trustworthy\r\n  build-depends:\r\n      base              >=4.12    && <4.23\r\n    , base-orphans      >=0.9.2   && <0.10\r\n    , deepseq           >=1.4.4.0 && <1.6\r\n    , hashable          >=1.4.4.0 && <1.6\r\n    , template-haskell\r\n    , time              >=1.8.0.2 && <1.9  || >=1.9.2 && <1.9.4 || >=1.10 && <1.10.1 || >=1.11 && <1.11.2 || >=1.12 && <1.13 || >=1.14 && <1.16\r\n\r\n  default-extensions:\r\n    BangPatterns\r\n    DeriveDataTypeable\r\n    DeriveGeneric\r\n    DeriveLift\r\n    PatternSynonyms\r\n    StandaloneDeriving\r\n    ViewPatterns\r\n\r\n  exposed-modules:\r\n    Data.Time.Calendar.Compat\r\n    Data.Time.Calendar.Easter.Compat\r\n    Data.Time.Calendar.Julian.Compat\r\n    Data.Time.Calendar.Month.Compat\r\n    Data.Time.Calendar.MonthDay.Compat\r\n    Data.Time.Calendar.OrdinalDate.Compat\r\n    Data.Time.Calendar.Quarter.Compat\r\n    Data.Time.Calendar.WeekDate.Compat\r\n    Data.Time.Clock.Compat\r\n    Data.Time.Clock.POSIX.Compat\r\n    Data.Time.Clock.System.Compat\r\n    Data.Time.Clock.TAI.Compat\r\n    Data.Time.Compat\r\n    Data.Time.Format.Compat\r\n    Data.Time.Format.ISO8601.Compat\r\n    Data.Time.LocalTime.Compat\r\n\r\n  other-modules:\r\n    Data.Format\r\n    Data.Time.Calendar.DayPeriod\r\n    Data.Time.Calendar.Private\r\n    Data.Time.Calendar.Types\r\n    Data.Time.Orphans\r\n\r\ntest-suite instances\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   test-instances\r\n  main-is:          Test.hs\r\n  build-depends:\r\n      base\r\n    , deepseq\r\n    , hashable          >=1.4.0.0 && <1.6\r\n    , HUnit             >=1.3.1   && <1.3.2 || >=1.6.0.0 && <1.7\r\n    , template-haskell\r\n    , time-compat\r\n\r\n-- This test-suite is from time library\r\n-- Changes:\r\n-- * imports: Data.Time -> Data.Time.Compat etc\r\n-- * disabled Test.Format.ParseTime\r\n-- * Test.Format.Format has also trees disabled\r\n-- * Test.Format.Compile doesn't work\r\n-- * disabled 'TimeOfDay minBound 0 0' (Test.LocalTime.Time)\r\n--\r\ntest-suite test-main\r\n  if !impl(ghc >=7.4)\r\n    buildable: False\r\n\r\n  default-language:   Haskell2010\r\n  type:               exitcode-stdio-1.0\r\n  hs-source-dirs:     test/main\r\n  default-extensions:\r\n    CPP\r\n    DefaultSignatures\r\n    DeriveDataTypeable\r\n    DerivingStrategies\r\n    ExistentialQuantification\r\n    FlexibleInstances\r\n    GeneralizedNewtypeDeriving\r\n    MultiParamTypeClasses\r\n    NumericUnderscores\r\n    Rank2Types\r\n    RecordWildCards\r\n    ScopedTypeVariables\r\n    StandaloneDeriving\r\n    TupleSections\r\n    TypeApplications\r\n    UndecidableInstances\r\n\r\n  ghc-options:        -Wall -fwarn-tabs\r\n  build-depends:\r\n      base\r\n    , deepseq\r\n    , QuickCheck        >=2.15.0.1 && <2.17\r\n    , random            >=1.2.1.3  && <1.4\r\n    , tasty             >=1.5      && <1.6\r\n    , tasty-hunit       >=0.10     && <0.11\r\n    , tasty-quickcheck  >=0.11     && <0.12\r\n    , time-compat\r\n\r\n  if !impl(ghc >=8.0)\r\n    build-depends:\r\n        fail        >=4.9.0.0 && <4.10\r\n      , semigroups  >=0.18.5  && <0.21\r\n\r\n  main-is:            Main.hs\r\n  other-modules:\r\n    Test.Arbitrary\r\n    Test.Calendar.AddDays\r\n    Test.Calendar.AddDaysRef\r\n    Test.Calendar.CalendarProps\r\n    Test.Calendar.Calendars\r\n    Test.Calendar.CalendarsRef\r\n    Test.Calendar.ClipDates\r\n    Test.Calendar.ClipDatesRef\r\n    Test.Calendar.ConvertBack\r\n    Test.Calendar.DayPeriod\r\n    Test.Calendar.Duration\r\n    Test.Calendar.Easter\r\n    Test.Calendar.EasterRef\r\n    Test.Calendar.LongWeekYears\r\n    Test.Calendar.LongWeekYearsRef\r\n    Test.Calendar.MonthDay\r\n    Test.Calendar.MonthDayRef\r\n    Test.Calendar.MonthOfYear\r\n    Test.Calendar.Valid\r\n    Test.Calendar.Week\r\n    Test.Calendar.Year\r\n    Test.Clock.Conversion\r\n    Test.Clock.Pattern\r\n    Test.Clock.Resolution\r\n    Test.Clock.TAI\r\n    Test.Format.Compile\r\n    Test.Format.Format\r\n    Test.Format.ISO8601\r\n    Test.Format.ParseTime\r\n    Test.LocalTime.CalendarDiffTime\r\n    Test.LocalTime.Time\r\n    Test.LocalTime.TimeOfDay\r\n    Test.LocalTime.TimeRef\r\n    Test.TestUtil\r\n    Test.Types\r\n\r\ntest-suite test-template\r\n  type:             exitcode-stdio-1.0\r\n  default-language: Haskell2010\r\n  hs-source-dirs:   test/template\r\n  main-is:          Main.hs\r\n  build-depends:\r\n      base\r\n    , tasty\r\n    , tasty-hunit\r\n    , template-haskell\r\n    , time-compat";
  }