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
      identifier = { name = "time"; version = "1.14"; };
      license = "BSD-2-Clause";
      copyright = "";
      maintainer = "<ashley@semantic.org>";
      author = "Ashley Yakeley";
      homepage = "https://github.com/haskell/time";
      url = "";
      synopsis = "A time library";
      description = "Time, clocks and calendars";
      buildType = "Configure";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ] ++ pkgs.lib.optional (system.isWindows) (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"));
        buildable = true;
      };
      tests = {
        "ShowDefaultTZAbbreviations" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ];
          buildable = true;
        };
        "ShowTime" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ];
          buildable = true;
        };
        "test-main" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ];
          buildable = true;
        };
        "test-unix" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = if system.isWindows then false else true;
        };
      };
      benchmarks = {
        "time-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/time-1.14.tar.gz";
      sha256 = "dfa0fe7cc9728e20d123a067161fa23ee27a5b180d58fa09d7738cb8ad737f3e";
    });
  }) // {
    package-description-override = "cabal-version:  3.0\r\nname:           time\r\nversion:        1.14\r\nx-revision: 1\r\nstability:      stable\r\nlicense:        BSD-2-Clause\r\nlicense-file:   LICENSE\r\nauthor:         Ashley Yakeley\r\nmaintainer:     <ashley@semantic.org>\r\nhomepage:       https://github.com/haskell/time\r\nbug-reports:    https://github.com/haskell/time/issues\r\nsynopsis:       A time library\r\ndescription:    Time, clocks and calendars\r\ncategory:       Time\r\nbuild-type:     Configure\r\ntested-with:\r\n    GHC == 9.4.8,\r\n    GHC == 9.6.4,\r\n    GHC == 9.8.2\r\nx-follows-version-policy:\r\n\r\nextra-source-files:\r\n    aclocal.m4\r\n    configure.ac\r\n    configure\r\n    lib/include/HsTime.h\r\n    lib/include/HsTimeConfig.h.in\r\n    test/unix/Test/Format/*.c\r\n    test/unix/Test/Format/*.h\r\nextra-tmp-files:\r\n    config.log\r\n    config.status\r\n    autom4te.cache\r\n    lib/include/HsTimeConfig.h\r\nextra-doc-files:\r\n    changelog.md\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/haskell/time\r\n\r\nlibrary\r\n    hs-source-dirs: lib\r\n    default-language: Haskell2010\r\n    default-extensions:\r\n        Rank2Types\r\n        DeriveDataTypeable\r\n        DeriveLift\r\n        DeriveGeneric\r\n        StandaloneDeriving\r\n        PatternSynonyms\r\n        ViewPatterns\r\n    ghc-options: -Wall -fwarn-tabs\r\n    c-sources: lib/cbits/HsTime.c\r\n    build-depends:\r\n        base >= 4.15 && < 5,\r\n        deepseq >= 1.1,\r\n        template-haskell >= 2.17,\r\n    if os(windows)\r\n        build-depends: Win32\r\n    exposed-modules:\r\n        Data.Time.Calendar,\r\n        Data.Time.Calendar.MonthDay,\r\n        Data.Time.Calendar.OrdinalDate,\r\n        Data.Time.Calendar.WeekDate,\r\n        Data.Time.Calendar.Julian,\r\n        Data.Time.Calendar.Easter,\r\n        Data.Time.Calendar.Month,\r\n        Data.Time.Calendar.Quarter,\r\n        Data.Time.Clock,\r\n        Data.Time.Clock.System,\r\n        Data.Time.Clock.POSIX,\r\n        Data.Time.Clock.TAI,\r\n        Data.Time.LocalTime,\r\n        Data.Time.Format,\r\n        Data.Time.Format.Internal,\r\n        Data.Time.Format.ISO8601,\r\n        Data.Time\r\n    other-modules:\r\n        Data.Format,\r\n        Data.Time.Calendar.CalendarDiffDays,\r\n        Data.Time.Calendar.Days,\r\n        Data.Time.Calendar.Gregorian,\r\n        Data.Time.Calendar.JulianYearDay,\r\n        Data.Time.Calendar.Private,\r\n        Data.Time.Calendar.Types,\r\n        Data.Time.Calendar.Week,\r\n        Data.Time.Clock.Internal.DiffTime,\r\n        Data.Time.Clock.Internal.AbsoluteTime,\r\n        Data.Time.Clock.Internal.NominalDiffTime,\r\n        Data.Time.Clock.Internal.POSIXTime,\r\n        Data.Time.Clock.Internal.UniversalTime,\r\n        Data.Time.Clock.Internal.SystemTime,\r\n        Data.Time.Clock.Internal.UTCTime,\r\n        Data.Time.Clock.Internal.CTimeval,\r\n        Data.Time.Clock.Internal.CTimespec,\r\n        Data.Time.Clock.Internal.UTCDiff,\r\n        Data.Time.LocalTime.Internal.TimeZone,\r\n        Data.Time.LocalTime.Internal.TimeOfDay,\r\n        Data.Time.LocalTime.Internal.CalendarDiffTime,\r\n        Data.Time.LocalTime.Internal.LocalTime,\r\n        Data.Time.LocalTime.Internal.ZonedTime,\r\n        Data.Time.Format.Parse,\r\n        Data.Time.Format.Locale,\r\n        Data.Time.Format.Format.Class,\r\n        Data.Time.Format.Format.Instances,\r\n        Data.Time.Format.Parse.Class,\r\n        Data.Time.Format.Parse.Instances\r\n    include-dirs: lib/include\r\n    if os(windows)\r\n        install-includes:\r\n            HsTime.h\r\n    else\r\n        autogen-includes:\r\n            HsTimeConfig.h\r\n        install-includes:\r\n            HsTime.h\r\n            HsTimeConfig.h\r\n\r\ntest-suite ShowDefaultTZAbbreviations\r\n    type: exitcode-stdio-1.0\r\n    hs-source-dirs: test\r\n    default-language: Haskell2010\r\n    ghc-options: -Wall -fwarn-tabs\r\n    build-depends:\r\n        base,\r\n        time\r\n    main-is: ShowDefaultTZAbbreviations.hs\r\n\r\ntest-suite ShowTime\r\n    type: exitcode-stdio-1.0\r\n    hs-source-dirs: test\r\n    default-language: Haskell2010\r\n    ghc-options: -Wall -fwarn-tabs\r\n    build-depends:\r\n        base,\r\n        time\r\n    main-is: ShowTime.hs\r\n\r\ntest-suite test-main\r\n    type: exitcode-stdio-1.0\r\n    hs-source-dirs: test/main\r\n    default-language: Haskell2010\r\n    default-extensions:\r\n        Rank2Types\r\n        TypeApplications\r\n        GeneralizedNewtypeDeriving\r\n        DeriveDataTypeable\r\n        StandaloneDeriving\r\n        DerivingStrategies\r\n        ExistentialQuantification\r\n        MultiParamTypeClasses\r\n        FlexibleInstances\r\n        UndecidableInstances\r\n        ScopedTypeVariables\r\n        TupleSections\r\n        RecordWildCards\r\n    ghc-options: -Wall -fwarn-tabs\r\n    build-depends:\r\n        base,\r\n        deepseq,\r\n        time,\r\n        random,\r\n        QuickCheck,\r\n        tasty,\r\n        tasty-hunit,\r\n        tasty-quickcheck,\r\n        template-haskell\r\n    main-is: Main.hs\r\n    other-modules:\r\n        Test.Types\r\n        Test.TestUtil\r\n        Test.Arbitrary\r\n        Test.Calendar.AddDays\r\n        Test.Calendar.AddDaysRef\r\n        Test.Calendar.CalendarProps\r\n        Test.Calendar.Calendars\r\n        Test.Calendar.CalendarsRef\r\n        Test.Calendar.ClipDates\r\n        Test.Calendar.ClipDatesRef\r\n        Test.Calendar.ConvertBack\r\n        Test.Calendar.Duration\r\n        Test.Calendar.Easter\r\n        Test.Calendar.EasterRef\r\n        Test.Calendar.DayPeriod\r\n        Test.Calendar.LongWeekYears\r\n        Test.Calendar.LongWeekYearsRef\r\n        Test.Calendar.MonthDay\r\n        Test.Calendar.MonthDayRef\r\n        Test.Calendar.MonthOfYear\r\n        Test.Calendar.Valid\r\n        Test.Calendar.Week\r\n        Test.Calendar.Year\r\n        Test.Clock.Conversion\r\n        Test.Clock.Lift\r\n        Test.Clock.Resolution\r\n        Test.Clock.TAI\r\n        Test.Format.Compile\r\n        Test.Format.Format\r\n        Test.Format.ParseTime\r\n        Test.Format.ISO8601\r\n        Test.LocalTime.CalendarDiffTime\r\n        Test.LocalTime.Time\r\n        Test.LocalTime.TimeOfDay\r\n        Test.LocalTime.TimeRef\r\n\r\ntest-suite test-unix\r\n    if os(windows)\r\n        buildable: False\r\n    type: exitcode-stdio-1.0\r\n    hs-source-dirs: test/unix\r\n    default-language: Haskell2010\r\n    default-extensions:\r\n        Rank2Types\r\n        DeriveDataTypeable\r\n        StandaloneDeriving\r\n        ExistentialQuantification\r\n        MultiParamTypeClasses\r\n        FlexibleInstances\r\n        UndecidableInstances\r\n        ScopedTypeVariables\r\n    ghc-options: -Wall -fwarn-tabs\r\n    c-sources: test/unix/Test/Format/FormatStuff.c\r\n    build-depends:\r\n        base,\r\n        deepseq,\r\n        time,\r\n        random,\r\n        QuickCheck,\r\n        tasty,\r\n        tasty-hunit,\r\n        tasty-quickcheck\r\n    main-is: Main.hs\r\n    other-modules:\r\n        Test.TestUtil\r\n        Test.Format.Format\r\n        Test.LocalTime.TimeZone\r\n\r\nbenchmark time-bench\r\n    type: exitcode-stdio-1.0\r\n    hs-source-dirs: benchmark\r\n    default-language: Haskell2010\r\n    ghc-options: -Wall -fwarn-tabs\r\n    build-depends:\r\n        base,\r\n        deepseq,\r\n        time,\r\n        criterion\r\n    main-is: Main.hs\r\n";
  }