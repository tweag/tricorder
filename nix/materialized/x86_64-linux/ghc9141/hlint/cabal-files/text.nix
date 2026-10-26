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
    flags = {
      developer = false;
      simdutf = true;
      pure-haskell = false;
      extendedbenchmarks = false;
    };
    package = {
      specVersion = "2.2";
      identifier = { name = "text"; version = "2.1.4"; };
      license = "BSD-2-Clause";
      copyright = "2009-2011 Bryan O'Sullivan, 2008-2009 Tom Harper, 2021 Andrew Lelechenko";
      maintainer = "Haskell Text Team <andrew.lelechenko@gmail.com>, Core Libraries Committee";
      author = "Bryan O'Sullivan <bos@serpentine.com>";
      homepage = "https://github.com/haskell/text";
      url = "";
      synopsis = "An efficient packed Unicode text type.";
      description = "\nAn efficient packed, immutable Unicode text type (both strict and\nlazy).\n\nThe 'Text' type represents Unicode character strings, in a time and\nspace-efficient manner. This package provides text processing\ncapabilities that are optimized for performance critical use, both\nin terms of large data quantities and high speed.\n\nThe 'Text' type provides character-encoding, type-safe case\nconversion via whole-string case conversion functions (see \"Data.Text\").\nIt also provides a range of functions for converting 'Text' values to\nand from 'ByteStrings', using several standard encodings\n(see \"Data.Text.Encoding\").\n\nEfficient locale-sensitive support for text IO is also supported\n(see \"Data.Text.IO\").\n\nThese modules are intended to be imported qualified, to avoid name\nclashes with Prelude functions, e.g.\n\n> import qualified Data.Text as T\n\n== ICU Support\n\nTo use an extended and very rich family of functions for working\nwith Unicode text (including normalization, regular expressions,\nnon-standard encodings, text breaking, and locales), see\nthe [text-icu package](https://hackage.haskell.org/package/text-icu)\nbased on the well-respected and liberally\nlicensed [ICU library](http://site.icu-project.org/).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ((((((([
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
        ] ++ pkgs.lib.optionals (flags.simdutf && !(system.isJavaScript || flags.pure-haskell)) (pkgs.lib.optional (compiler.isGhc && compiler.version.ge "9.4") (hsPkgs."system-cxx-std-lib" or (errorHandler.buildDepError "system-cxx-std-lib")))) ++ pkgs.lib.optional (flags.simdutf && system.isWindows && (compiler.isGhc && (compiler.version.ge "8.8" && compiler.version.lt "8.10.5" || compiler.version.eq "9.0.1"))) (hsPkgs."base" or (errorHandler.buildDepError "base"))) ++ pkgs.lib.optional (system.isWindows && (compiler.isGhc && (compiler.version.ge "8.2" && compiler.version.lt "8.4" || compiler.version.eq "8.6.3" || compiler.version.eq "8.10.1"))) (hsPkgs."base" or (errorHandler.buildDepError "base"))) ++ pkgs.lib.optional ((system.isAarch64 || system.isArm) && (compiler.isGhc && (compiler.version.ge "8.10" && compiler.version.lt "8.11"))) (hsPkgs."base" or (errorHandler.buildDepError "base"))) ++ pkgs.lib.optional ((system.isAarch64 || system.isArm) && (compiler.isGhc && compiler.version.eq "9.2.1")) (hsPkgs."base" or (errorHandler.buildDepError "base"))) ++ pkgs.lib.optional (flags.simdutf && system.isNetbsd && (compiler.isGhc && compiler.version.lt "9.4")) (hsPkgs."base" or (errorHandler.buildDepError "base"))) ++ (if compiler.isGhc && compiler.version.lt "9.14"
          then [
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ]
          else [
            (hsPkgs."template-haskell-lift" or (errorHandler.buildDepError "template-haskell-lift"))
          ])) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.4") (hsPkgs."data-array-byte" or (errorHandler.buildDepError "data-array-byte"));
        libs = pkgs.lib.optionals (flags.simdutf && !(system.isJavaScript || flags.pure-haskell)) (pkgs.lib.optionals (!(compiler.isGhc && compiler.version.ge "9.4")) (if system.isOsx || system.isFreebsd
          then [ (pkgs."c++" or (errorHandler.sysDepError "c++")) ]
          else if system.isOpenbsd
            then [
              (pkgs."c++" or (errorHandler.sysDepError "c++"))
              (pkgs."c++abi" or (errorHandler.sysDepError "c++abi"))
              (pkgs."pthread" or (errorHandler.sysDepError "pthread"))
            ]
            else if system.isWindows
              then if compiler.isGhc && compiler.version.lt "9.3"
                then [ (pkgs."stdc++" or (errorHandler.sysDepError "stdc++")) ]
                else [
                  (pkgs."c++" or (errorHandler.sysDepError "c++"))
                  (pkgs."c++abi" or (errorHandler.sysDepError "c++abi"))
                ]
              else if system.isWasm32
                then [
                  (pkgs."c++" or (errorHandler.sysDepError "c++"))
                  (pkgs."c++abi" or (errorHandler.sysDepError "c++abi"))
                ]
                else [
                  (pkgs."stdc++" or (errorHandler.sysDepError "stdc++"))
                ]));
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = ((([
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.4") (hsPkgs."data-array-byte" or (errorHandler.buildDepError "data-array-byte"))) ++ (if compiler.isGhc && compiler.version.lt "9.14"
            then [
              (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            ]
            else [
              (hsPkgs."template-haskell-lift" or (errorHandler.buildDepError "template-haskell-lift"))
            ])) ++ pkgs.lib.optional (compiler.isGhc && (compiler.version.ge "8.2.1" && compiler.version.lt "8.6" || compiler.version.ge "8.6.2" && compiler.version.lt "9.2" || compiler.version.ge "9.2.2")) (hsPkgs."tasty-inspection-testing" or (errorHandler.buildDepError "tasty-inspection-testing"))) ++ pkgs.lib.optional (system.isOpenbsd) (hsPkgs."splitmix" or (errorHandler.buildDepError "splitmix"));
          buildable = true;
        };
      };
      benchmarks = {
        "text-benchmarks" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/text-2.1.4.tar.gz";
      sha256 = "162e8f77c2e7b0c46457a044573bc489fdd624cdc40bdde9b70b47924c081074";
    });
  }) // {
    package-description-override = "cabal-version:  2.2\r\nname:           text\r\nversion:        2.1.4\r\n\r\nhomepage:       https://github.com/haskell/text\r\nbug-reports:    https://github.com/haskell/text/issues\r\nsynopsis:       An efficient packed Unicode text type.\r\ndescription:\r\n    .\r\n    An efficient packed, immutable Unicode text type (both strict and\r\n    lazy).\r\n    .\r\n    The 'Text' type represents Unicode character strings, in a time and\r\n    space-efficient manner. This package provides text processing\r\n    capabilities that are optimized for performance critical use, both\r\n    in terms of large data quantities and high speed.\r\n    .\r\n    The 'Text' type provides character-encoding, type-safe case\r\n    conversion via whole-string case conversion functions (see \"Data.Text\").\r\n    It also provides a range of functions for converting 'Text' values to\r\n    and from 'ByteStrings', using several standard encodings\r\n    (see \"Data.Text.Encoding\").\r\n    .\r\n    Efficient locale-sensitive support for text IO is also supported\r\n    (see \"Data.Text.IO\").\r\n    .\r\n    These modules are intended to be imported qualified, to avoid name\r\n    clashes with Prelude functions, e.g.\r\n    .\r\n    > import qualified Data.Text as T\r\n    .\r\n    == ICU Support\r\n    .\r\n    To use an extended and very rich family of functions for working\r\n    with Unicode text (including normalization, regular expressions,\r\n    non-standard encodings, text breaking, and locales), see\r\n    the [text-icu package](https://hackage.haskell.org/package/text-icu)\r\n    based on the well-respected and liberally\r\n    licensed [ICU library](http://site.icu-project.org/).\r\n\r\nlicense:        BSD-2-Clause\r\nlicense-file:   LICENSE\r\nauthor:         Bryan O'Sullivan <bos@serpentine.com>\r\nmaintainer:     Haskell Text Team <andrew.lelechenko@gmail.com>, Core Libraries Committee\r\ncopyright:      2009-2011 Bryan O'Sullivan, 2008-2009 Tom Harper, 2021 Andrew Lelechenko\r\ncategory:       Data, Text\r\nbuild-type:     Simple\r\ntested-with:\r\n    GHC == 8.4.4\r\n    GHC == 8.6.5\r\n    GHC == 8.8.4\r\n    GHC == 8.10.7\r\n    GHC == 9.0.2\r\n    GHC == 9.2.8\r\n    GHC == 9.4.8\r\n    GHC == 9.6.7\r\n    GHC == 9.8.4\r\n    GHC == 9.10.1\r\n    GHC == 9.12.2\r\n\r\nextra-source-files:\r\n    -- scripts/CaseFolding.txt\r\n    -- scripts/SpecialCasing.txt\r\n    scripts/*.hs\r\n    simdutf/LICENSE-APACHE\r\n    simdutf/LICENSE-MIT\r\n    simdutf/simdutf_c.h\r\n    simdutf/simdutf.h\r\n    tests/literal-rule-test.sh\r\n    tests/LiteralRuleTest.hs\r\nextra-doc-files:\r\n    README.md\r\n    changelog.md\r\n\r\nflag developer\r\n  description: operate in developer mode\r\n  default: False\r\n  manual: True\r\n\r\nflag simdutf\r\n  description: use simdutf library, causes Data.Text.Internal.Validate.Simd to be exposed\r\n  default: True\r\n  manual: True\r\n\r\nflag pure-haskell\r\n  description: Don't use text's standard C routines\r\n    NB: This feature is not fully implemented. Several C routines are still in\r\n    use.\r\n\r\n    When this flag is true, text will use pure Haskell variants of the\r\n    routines. This is not recommended except for use with GHC's JavaScript\r\n    backend.\r\n\r\n    This flag also disables simdutf.\r\n\r\n  default: False\r\n  manual: True\r\n\r\nflag ExtendedBenchmarks\r\n  description: Runs extra benchmarks which can be very slow.\r\n  default: False\r\n  manual: True\r\n\r\nlibrary\r\n  if arch(javascript) || flag(pure-haskell)\r\n    cpp-options: -DPURE_HASKELL\r\n  else\r\n    c-sources:  cbits/is_ascii.c\r\n                cbits/reverse.c\r\n                cbits/utils.c\r\n    if (arch(aarch64))\r\n      c-sources: cbits/aarch64/measure_off.c\r\n    else\r\n      c-sources: cbits/measure_off.c\r\n\r\n  hs-source-dirs: src\r\n\r\n  if flag(simdutf) && !(arch(javascript) || flag(pure-haskell))\r\n    exposed-modules: Data.Text.Internal.Validate.Simd\r\n    include-dirs: simdutf\r\n    c-sources: simdutf/hs_simdutf.c\r\n    cxx-sources: simdutf/simdutf.cpp\r\n    cxx-options: -std=c++17\r\n    cpp-options: -DSIMDUTF\r\n    if impl(ghc >= 9.4)\r\n      build-depends: system-cxx-std-lib == 1.0\r\n    elif os(darwin) || os(freebsd)\r\n      extra-libraries: c++\r\n    elif os(openbsd)\r\n      extra-libraries: c++ c++abi pthread\r\n    elif os(windows)\r\n      -- GHC's Windows toolchain is based on clang/libc++ in GHC 9.4 and later\r\n      if impl(ghc < 9.3)\r\n        extra-libraries: stdc++\r\n      else\r\n        extra-libraries: c++ c++abi\r\n    elif arch(wasm32)\r\n      cpp-options: -DSIMDUTF_NO_THREADS\r\n      cxx-options: -fno-exceptions\r\n      extra-libraries: c++ c++abi\r\n    else\r\n      extra-libraries: stdc++\r\n\r\n  -- Certain version of GHC crash on Windows, when TemplateHaskell encounters C++.\r\n  -- https://gitlab.haskell.org/ghc/ghc/-/issues/19417\r\n  if flag(simdutf) && os(windows) && impl(ghc >= 8.8 && < 8.10.5 || == 9.0.1)\r\n    build-depends: base < 0\r\n\r\n  -- For GHC 8.2, 8.6.3 and 8.10.1 even TH + C crash Windows linker.\r\n  if os(windows) && impl(ghc >= 8.2 && < 8.4 || == 8.6.3 || == 8.10.1)\r\n    build-depends: base < 0\r\n\r\n  -- GHC 8.10 has linking issues (probably TH-related) on ARM.\r\n  if (arch(aarch64) || arch(arm)) && impl(ghc == 8.10.*)\r\n    build-depends: base < 0\r\n\r\n  -- Subword primitives in GHC 9.2.1 are broken on ARM platforms.\r\n  if (arch(aarch64) || arch(arm)) && impl(ghc == 9.2.1)\r\n    build-depends: base < 0\r\n\r\n  -- NetBSD + GHC 9.2.1 + TH + C++ does not work together.\r\n  -- https://gitlab.haskell.org/ghc/ghc/-/issues/22577\r\n  if flag(simdutf) && os(netbsd) && impl(ghc < 9.4)\r\n    build-depends: base < 0\r\n\r\n  exposed-modules:\r\n    Data.Text\r\n    Data.Text.Array\r\n    Data.Text.Encoding\r\n    Data.Text.Encoding.Error\r\n    Data.Text.Foreign\r\n    Data.Text.IO\r\n    Data.Text.IO.Utf8\r\n    Data.Text.Internal\r\n    Data.Text.Internal.ArrayUtils\r\n    Data.Text.Internal.Builder\r\n    Data.Text.Internal.Builder.Functions\r\n    Data.Text.Internal.Builder.Int.Digits\r\n    Data.Text.Internal.Builder.RealFloat.Functions\r\n    Data.Text.Internal.ByteStringCompat\r\n    Data.Text.Internal.PrimCompat\r\n    Data.Text.Internal.Encoding\r\n    Data.Text.Internal.Encoding.Fusion\r\n    Data.Text.Internal.Encoding.Fusion.Common\r\n    Data.Text.Internal.Encoding.Utf16\r\n    Data.Text.Internal.Encoding.Utf32\r\n    Data.Text.Internal.Encoding.Utf8\r\n    Data.Text.Internal.Fusion\r\n    Data.Text.Internal.Fusion.CaseMapping\r\n    Data.Text.Internal.Fusion.Common\r\n    Data.Text.Internal.Fusion.Size\r\n    Data.Text.Internal.Fusion.Types\r\n    Data.Text.Internal.IO\r\n    Data.Text.Internal.Lazy\r\n    Data.Text.Internal.Lazy.Encoding.Fusion\r\n    Data.Text.Internal.Lazy.Fusion\r\n    Data.Text.Internal.Lazy.Search\r\n    Data.Text.Internal.Private\r\n    Data.Text.Internal.Read\r\n    Data.Text.Internal.Search\r\n    Data.Text.Internal.StrictBuilder\r\n    Data.Text.Internal.Unsafe\r\n    Data.Text.Internal.Unsafe.Char\r\n    Data.Text.Internal.Validate\r\n    Data.Text.Internal.Validate.Native\r\n    Data.Text.Lazy\r\n    Data.Text.Lazy.Builder\r\n    Data.Text.Lazy.Builder.Int\r\n    Data.Text.Lazy.Builder.RealFloat\r\n    Data.Text.Lazy.Encoding\r\n    Data.Text.Lazy.IO\r\n    Data.Text.Lazy.Internal\r\n    Data.Text.Lazy.Read\r\n    Data.Text.Read\r\n    Data.Text.Unsafe\r\n\r\n  other-modules:\r\n    Data.Text.Show\r\n    Data.Text.Internal.Measure\r\n    Data.Text.Internal.Reverse\r\n    Data.Text.Internal.Transformation\r\n    Data.Text.Internal.IsAscii\r\n\r\n  build-depends:\r\n    array            >= 0.3 && < 0.6,\r\n    base             >= 4.11 && < 5,\r\n    binary           >= 0.8.3 && < 0.9,\r\n    bytestring       >= 0.10.4 && < 0.13,\r\n    deepseq          >= 1.1 && < 1.6,\r\n    ghc-prim         >= 0.2 && < 0.15,\r\n\r\n  -- template-haskell-lift was added as a boot library in GHC-9.14\r\n  -- once we no longer wish to backport releases to older major releases of GHC,\r\n  -- this conditional can be dropped\r\n  if impl(ghc < 9.14)\r\n    build-depends: template-haskell >= 2.5 && < 3\r\n  else\r\n    build-depends: template-haskell-lift >= 0.1 && <0.2\r\n\r\n  if impl(ghc < 9.4)\r\n    build-depends: data-array-byte >= 0.1 && < 0.2\r\n\r\n  ghc-options: -Wall -fwarn-tabs -funbox-strict-fields -O2\r\n  if flag(developer)\r\n    ghc-options: -fno-ignore-asserts\r\n    cpp-options: -DASSERTS\r\n    if impl(ghc >= 9.2.2)\r\n      ghc-options: -fcheck-prim-bounds\r\n\r\n  default-language: Haskell2010\r\n  default-extensions:\r\n    NondecreasingIndentation\r\n  other-extensions:\r\n    BangPatterns\r\n    CPP\r\n    DeriveDataTypeable\r\n    ExistentialQuantification\r\n    ForeignFunctionInterface\r\n    GeneralizedNewtypeDeriving\r\n    MagicHash\r\n    OverloadedStrings\r\n    Rank2Types\r\n    RankNTypes\r\n    RecordWildCards\r\n    Safe\r\n    ScopedTypeVariables\r\n    TemplateHaskellQuotes\r\n    Trustworthy\r\n    TypeFamilies\r\n    UnboxedTuples\r\n    UnliftedFFITypes\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskell/text\r\n\r\ntest-suite tests\r\n  type:           exitcode-stdio-1.0\r\n  ghc-options:\r\n    -Wall -threaded -rtsopts -with-rtsopts=-N\r\n\r\n  hs-source-dirs: tests\r\n  main-is:        Tests.hs\r\n  other-modules:\r\n    Tests.Lift\r\n    Tests.Properties\r\n    Tests.Properties.Basics\r\n    Tests.Properties.Builder\r\n    Tests.Properties.Folds\r\n    Tests.Properties.Instances\r\n    Tests.Properties.LowLevel\r\n    Tests.Properties.Read\r\n    Tests.Properties.Substrings\r\n    Tests.Properties.Text\r\n    Tests.Properties.Transcoding\r\n    Tests.Properties.CornerCases\r\n    Tests.Properties.Validate\r\n    Tests.QuickCheckUtils\r\n    Tests.RebindableSyntaxTest\r\n    Tests.Regressions\r\n    Tests.SlowFunctions\r\n    Tests.ShareEmpty\r\n    Tests.Utils\r\n\r\n  build-depends:\r\n    QuickCheck >= 2.12.6 && < 2.18,\r\n    base <5,\r\n    binary,\r\n    bytestring,\r\n    deepseq,\r\n    ghc-prim,\r\n    tasty,\r\n    tasty-hunit,\r\n    tasty-quickcheck,\r\n    temporary,\r\n    transformers,\r\n    text\r\n  if impl(ghc < 9.4)\r\n    build-depends: data-array-byte >= 0.1 && < 0.2\r\n  if impl(ghc < 9.14)\r\n    build-depends: template-haskell\r\n  else\r\n    build-depends: template-haskell-lift\r\n\r\n  -- Plugin infrastructure does not work properly in 8.6.1, and\r\n  -- ghc-9.2.1 library depends on parsec, which causes a circular dependency.\r\n  if impl(ghc >= 8.2.1 && < 8.6 || >= 8.6.2 && < 9.2 || >= 9.2.2)\r\n    build-depends: tasty-inspection-testing\r\n\r\n  -- https://github.com/haskellari/splitmix/issues/101\r\n  if os(openbsd)\r\n    build-depends: splitmix < 0.1.3 || > 0.1.3.1\r\n\r\n  default-language: Haskell2010\r\n  default-extensions: NondecreasingIndentation\r\n\r\nbenchmark text-benchmarks\r\n  type:           exitcode-stdio-1.0\r\n\r\n  ghc-options:    -Wall -O2 -rtsopts \"-with-rtsopts=-A32m\"\r\n  if impl(ghc >= 8.6)\r\n    ghc-options:  -fproc-alignment=64\r\n  if flag(ExtendedBenchmarks)\r\n    cpp-options: -DExtendedBenchmarks\r\n\r\n  build-depends:  base,\r\n                  bytestring >= 0.10.4,\r\n                  containers,\r\n                  deepseq,\r\n                  directory,\r\n                  filepath,\r\n                  tasty-bench >= 0.2,\r\n                  temporary,\r\n                  text,\r\n                  transformers\r\n\r\n  hs-source-dirs: benchmarks/haskell\r\n  main-is:        Benchmarks.hs\r\n  other-modules:\r\n    Benchmarks.Builder\r\n    Benchmarks.Concat\r\n    Benchmarks.DecodeUtf8\r\n    Benchmarks.EncodeUtf8\r\n    Benchmarks.Equality\r\n    Benchmarks.FileRead\r\n    Benchmarks.FileWrite\r\n    Benchmarks.FoldLines\r\n    Benchmarks.Micro\r\n    Benchmarks.Multilang\r\n    Benchmarks.Programs.BigTable\r\n    Benchmarks.Programs.Cut\r\n    Benchmarks.Programs.Fold\r\n    Benchmarks.Programs.Sort\r\n    Benchmarks.Programs.StripTags\r\n    Benchmarks.Programs.Throughput\r\n    Benchmarks.Pure\r\n    Benchmarks.ReadNumbers\r\n    Benchmarks.Replace\r\n    Benchmarks.Search\r\n    Benchmarks.Stream\r\n    Benchmarks.WordFrequencies\r\n\r\n  default-language: Haskell2010\r\n  default-extensions: NondecreasingIndentation\r\n  other-extensions: DeriveGeneric\r\n";
  }