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
      identifier = { name = "regex"; version = "1.1.0.2"; };
      license = "BSD-3-Clause";
      copyright = "Chris Dornan 2016-2017";
      maintainer = "Chris Dornan <chris@regex.uk>";
      author = "Chris Dornan";
      homepage = "http://regex.uk";
      url = "";
      synopsis = "Toolkit for regex-base";
      description = "A regular expression toolkit for regex-base with\ncompile-time checking of RE syntax, data types for\nmatches and captures, a text replacement toolkit,\nportable options, high-level AWK-like tools\nfor building text processing apps, regular expression\nmacros with parsers and test bench, comprehensive\ndocumentation, tutorials and copious examples.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."regex-base" or (errorHandler.buildDepError "regex-base"))
          (hsPkgs."regex-pcre-builtin" or (errorHandler.buildDepError "regex-pcre-builtin"))
          (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."time-locale-compat" or (errorHandler.buildDepError "time-locale-compat"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/regex-1.1.0.2.tar.gz";
      sha256 = "8a0404896452272d18bd9db078bd7d982b6268aa5bcf0d6fe5aa5256f174fedb";
    });
  }) // {
    package-description-override = "Name:                   regex\nVersion:                1.1.0.2\nSynopsis:               Toolkit for regex-base\nDescription:            A regular expression toolkit for regex-base with\n                        compile-time checking of RE syntax, data types for\n                        matches and captures, a text replacement toolkit,\n                        portable options, high-level AWK-like tools\n                        for building text processing apps, regular expression\n                        macros with parsers and test bench, comprehensive\n                        documentation, tutorials and copious examples.\nHomepage:               http://regex.uk\nAuthor:                 Chris Dornan\nLicense:                BSD3\nlicense-file:           LICENSE\nMaintainer:             Chris Dornan <chris@regex.uk>\nCopyright:              Chris Dornan 2016-2017\nCategory:               Text\nBuild-type:             Simple\nStability:              Stable\nbug-reports:            http://issues.regex.uk\n\nExtra-Source-Files:\n    README.md\n    changelog\n\nCabal-Version:          >= 1.10\n\nSource-Repository head\n    type:               git\n    location:           https://github.com/iconnect/regex.git\n\nSource-Repository this\n    Type:               git\n    Location:           https://github.com/iconnect/regex.git\n    Tag:                1.1.0.2\n\n\n\nLibrary\n    Hs-Source-Dirs:     .\n    Exposed-Modules:\n      Text.RE\n      Text.RE.REOptions\n      Text.RE.Replace\n      Text.RE.Summa\n      Text.RE.TDFA\n      Text.RE.TDFA.ByteString\n      Text.RE.TDFA.ByteString.Lazy\n      Text.RE.TDFA.Sequence\n      Text.RE.TDFA.String\n      Text.RE.TDFA.Text\n      Text.RE.TDFA.Text.Lazy\n      Text.RE.TestBench\n      Text.RE.TestBench.Parsers\n      Text.RE.Tools\n      Text.RE.Tools.Edit\n      Text.RE.Tools.Find\n      Text.RE.Tools.Grep\n      Text.RE.Tools.IsRegex\n      Text.RE.Tools.Lex\n      Text.RE.Tools.Sed\n      Text.RE.ZeInternals\n      Text.RE.ZeInternals.Types.Poss\n\n    Other-Modules:\n      Text.RE.ZeInternals.AddCaptureNames\n      Text.RE.ZeInternals.EscapeREString\n      Text.RE.ZeInternals.NamedCaptures\n      Text.RE.ZeInternals.PreludeMacros\n      Text.RE.ZeInternals.QQ\n      Text.RE.ZeInternals.Replace\n      Text.RE.ZeInternals.SearchReplace\n      Text.RE.ZeInternals.SearchReplace.TDFA\n      Text.RE.ZeInternals.SearchReplace.TDFA.ByteString\n      Text.RE.ZeInternals.SearchReplace.TDFA.ByteString.Lazy\n      Text.RE.ZeInternals.SearchReplace.TDFA.Sequence\n      Text.RE.ZeInternals.SearchReplace.TDFA.String\n      Text.RE.ZeInternals.SearchReplace.TDFA.Text\n      Text.RE.ZeInternals.SearchReplace.TDFA.Text.Lazy\n      Text.RE.ZeInternals.SearchReplace.TDFAEdPrime\n      Text.RE.ZeInternals.TDFA\n      Text.RE.ZeInternals.TestBench\n      Text.RE.ZeInternals.TestBench.Parsers\n      Text.RE.ZeInternals.Tools.Lex\n      Text.RE.ZeInternals.Types.Capture\n      Text.RE.ZeInternals.Types.CaptureID\n      Text.RE.ZeInternals.Types.IsRegex\n      Text.RE.ZeInternals.Types.LineNo\n      Text.RE.ZeInternals.Types.Match\n      Text.RE.ZeInternals.Types.Matches\n      Text.RE.ZeInternals.Types.SearchReplace\n\n\n    Default-Language:   Haskell2010\n\n    Other-Extensions:\n      AllowAmbiguousTypes\n      CPP\n      DeriveDataTypeable\n      DeriveGeneric\n      ExistentialQuantification\n      FlexibleContexts\n      FlexibleInstances\n      FunctionalDependencies\n      GeneralizedNewtypeDeriving\n      MultiParamTypeClasses\n      NoImplicitPrelude\n      OverloadedStrings\n      QuasiQuotes\n      RecordWildCards\n      ScopedTypeVariables\n      TemplateHaskell\n      TypeSynonymInstances\n      UndecidableInstances\n\n    if !impl(ghc >= 8.0)\n      Other-Extensions: TemplateHaskell\n    else\n      Other-Extensions: TemplateHaskellQuotes\n\n    GHC-Options:\n      -Wall\n      -fwarn-tabs\n      -Wwarn\n\n    Build-depends:\n        array                >= 0.4\n      , base                 >= 4        && <  5\n      , base-compat          >= 0.6      && <  1\n      , bytestring           >= 0.10\n      , containers           >= 0.4\n      , hashable             >= 1.2\n      , regex-base           >= 0.93\n      , regex-pcre-builtin   >= 0.94\n      , regex-tdfa           >= 1.3.1.0\n      , template-haskell     >= 2.7\n      , text                 >= 1.2\n      , time                 >= 1.4.2\n      , time-locale-compat   >= 0.1\n      , transformers         >= 0.2.2\n      , unordered-containers >= 0.2\n      , utf8-string          >= 1\n\n\n-- Generated with re-gen-cabals\n";
  }