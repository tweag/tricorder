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
    flags = { binary = true; parsec = true; attoparsec = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "parsers"; version = "0.12.12"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2010-2013 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/parsers/";
      url = "";
      synopsis = "Parsing combinators";
      description = "This library provides convenient combinators for working with and building parsing combinator libraries.\n\nGiven a few simple instances, e.g. for the class 'Text.Parser.Combinators.Parsing' in \"Text.Parser.Combinators.Parsing\" you\nget access to a large number of canned definitions. Instances exist for the parsers provided by @parsec@,\n@attoparsec@ and base’s \"Text.Read\".";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ((([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."charset" or (errorHandler.buildDepError "charset"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
        ] ++ pkgs.lib.optional (flags.binary) (hsPkgs."binary" or (errorHandler.buildDepError "binary"))) ++ pkgs.lib.optional (flags.parsec) (hsPkgs."parsec" or (errorHandler.buildDepError "parsec"))) ++ pkgs.lib.optional (flags.attoparsec) (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.0") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
        buildable = true;
      };
      tests = {
        "quickcheck" = {
          depends = ([
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."parsers" or (errorHandler.buildDepError "parsers"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
          ] ++ pkgs.lib.optional (flags.parsec) (hsPkgs."parsec" or (errorHandler.buildDepError "parsec"))) ++ pkgs.lib.optional (flags.attoparsec) (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"));
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/parsers-0.12.12.tar.gz";
      sha256 = "dd9e538b7a9e732a5a4241d6de01d298aff4bb19a9582e9464ee4ba660c626bc";
    });
  }) // {
    package-description-override = "name:          parsers\r\ncategory:      Text, Parsing\r\nversion:       0.12.12\r\nx-revision: 1\r\nlicense:       BSD3\r\ncabal-version: >= 1.10\r\nlicense-file:  LICENSE\r\nauthor:        Edward A. Kmett\r\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\r\nstability:     experimental\r\nhomepage:      http://github.com/ekmett/parsers/\r\nbug-reports:   http://github.com/ekmett/parsers/issues\r\ncopyright:     Copyright (C) 2010-2013 Edward A. Kmett\r\nsynopsis:      Parsing combinators\r\ndescription:\r\n  This library provides convenient combinators for working with and building parsing combinator libraries.\r\n  .\r\n  Given a few simple instances, e.g. for the class 'Text.Parser.Combinators.Parsing' in \"Text.Parser.Combinators.Parsing\" you\r\n  get access to a large number of canned definitions. Instances exist for the parsers provided by @parsec@,\r\n  @attoparsec@ and base’s \"Text.Read\".\r\nbuild-type:    Simple\r\ntested-with:   GHC==8.0.2\r\n             , GHC==8.2.2\r\n             , GHC==8.4.4\r\n             , GHC==8.6.5\r\n             , GHC==8.8.4\r\n             , GHC==8.10.7\r\n             , GHC==9.0.2\r\n             , GHC==9.2.8\r\n             , GHC==9.4.8\r\n             , GHC==9.6.6\r\n             , GHC==9.8.2\r\n             , GHC==9.10.1\r\n\r\nextra-source-files:\r\n  .hlint.yaml\r\n  CHANGELOG.markdown\r\n  README.markdown\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/ekmett/parsers.git\r\n\r\nflag binary\r\n  default: True\r\n  description:\r\n    You can disable the use of the `binary` package using `-f-binary`.\r\n\r\nflag parsec\r\n  default: True\r\n  description:\r\n    You can disable the use of the `parsec` package using `-f-parsec`.\r\n\r\nflag attoparsec\r\n  default: True\r\n  description:\r\n    You can disable the use of the `attoparsec` package using `-f-attoparsec`.\r\n\r\nlibrary\r\n  default-language: Haskell2010\r\n  exposed-modules:\r\n    Text.Parser.Char\r\n    Text.Parser.Combinators\r\n    Text.Parser.LookAhead\r\n    Text.Parser.Permutation\r\n    Text.Parser.Expression\r\n    Text.Parser.Token\r\n    Text.Parser.Token.Style\r\n    Text.Parser.Token.Highlight\r\n\r\n  hs-source-dirs: src\r\n\r\n  ghc-options: -Wall -Wno-wrong-do-bind -Wmonomorphism-restriction -Wincomplete-record-updates -Widentities -Wincomplete-uni-patterns -Wno-trustworthy-safe\r\n\r\n  build-depends:\r\n    base                 >= 4.9      && < 5,\r\n    charset              >= 0.3      && < 1,\r\n    containers           >= 0.4      && < 0.9,\r\n    text                 >= 0.10     && < 2.2,\r\n    transformers         >= 0.2      && < 0.7,\r\n    mtl                  >= 2.0.1    && < 2.4,\r\n    scientific           >= 0.3      && < 0.4,\r\n    unordered-containers >= 0.2      && < 0.3\r\n\r\n  if flag(binary)\r\n    build-depends: binary     >= 0.7.2    && < 1\r\n  if flag(parsec)\r\n    build-depends: parsec     >= 3.1      && < 3.2\r\n  if flag(attoparsec)\r\n    build-depends: attoparsec >= 0.12.1.4 && < 0.15\r\n  if impl(ghc < 8.0)\r\n    build-depends: semigroups >= 0.12     && < 1\r\n\r\ntest-suite quickcheck\r\n  type:    exitcode-stdio-1.0\r\n  main-is: QuickCheck.hs\r\n  default-language: Haskell2010\r\n  build-depends:\r\n    base == 4.*,\r\n    bytestring,\r\n    parsers,\r\n    QuickCheck,\r\n    quickcheck-instances\r\n  ghc-options: -Wall -threaded\r\n  hs-source-dirs: tests\r\n\r\n  if flag(parsec)\r\n    build-depends: parsec >= 3\r\n  if flag(attoparsec)\r\n    build-depends: attoparsec\r\n";
  }