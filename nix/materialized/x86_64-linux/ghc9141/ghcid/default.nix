{
  pkgs = hackage:
    {
      packages = {
        conduit.revision = import ./cabal-files/conduit.nix;
        base16-bytestring.revision = import ./cabal-files/base16-bytestring.nix;
        string-interpolate.revision = import ./cabal-files/string-interpolate.nix;
        string-interpolate.flags.text-builder = false;
        string-interpolate.flags.bytestring-builder = false;
        string-interpolate.flags.extended-benchmarks = false;
        filepath.revision = hackage.filepath."1.5.4.0".revisions.default;
        attoparsec.revision = import ./cabal-files/attoparsec.nix;
        attoparsec.flags.developer = false;
        base64-bytestring.revision = import ./cabal-files/base64-bytestring.nix;
        unordered-containers.revision = import ./cabal-files/unordered-containers.nix;
        unordered-containers.flags.debug = false;
        unix-time.revision = import ./cabal-files/unix-time.nix;
        transformers-base.revision = import ./cabal-files/transformers-base.nix;
        transformers-base.flags.orphaninstances = true;
        tasty.revision = import ./cabal-files/tasty.nix;
        tasty.flags.terminal-size = true;
        tasty.flags.unix = true;
        fsnotify.revision = import ./cabal-files/fsnotify.nix;
        monad-logger.revision = import ./cabal-files/monad-logger.nix;
        monad-logger.flags.template_haskell = true;
        vector-stream.revision = import ./cabal-files/vector-stream.nix;
        ghc-bignum.revision = hackage.ghc-bignum."1.4".revisions.default;
        stm.revision = hackage.stm."2.5.3.1".revisions.default;
        typed-process.revision = import ./cabal-files/typed-process.nix;
        transformers.revision = hackage.transformers."0.6.1.2".revisions.default;
        deepseq.revision = hackage.deepseq."1.5.1.0".revisions.default;
        auto-update.revision = import ./cabal-files/auto-update.nix;
        optparse-applicative.revision = import ./cabal-files/optparse-applicative.nix;
        optparse-applicative.flags.process = true;
        streaming-commons.revision = import ./cabal-files/streaming-commons.nix;
        streaming-commons.flags.use-bytestring-builder = false;
        split.revision = import ./cabal-files/split.nix;
        directory.revision = hackage.directory."1.3.10.0".revisions.default;
        stm-chans.revision = import ./cabal-files/stm-chans.nix;
        file-io.revision = hackage.file-io."0.1.5".revisions.default;
        lifted-base.revision = import ./cabal-files/lifted-base.nix;
        cryptohash-sha256.revision = import ./cabal-files/cryptohash-sha256.nix;
        cryptohash-sha256.flags.exe = false;
        cryptohash-sha256.flags.use-cbits = true;
        th-abstraction.revision = import ./cabal-files/th-abstraction.nix;
        mtl.revision = hackage.mtl."2.3.1".revisions.default;
        ansi-terminal-types.revision = import ./cabal-files/ansi-terminal-types.nix;
        process.revision = hackage.process."1.6.26.1".revisions.default;
        base.revision = hackage.base."4.22.0.0".revisions.default;
        fast-logger.revision = import ./cabal-files/fast-logger.nix;
        haskell-src-exts.revision = import ./cabal-files/haskell-src-exts.nix;
        base-orphans.revision = import ./cabal-files/base-orphans.nix;
        extra.revision = import ./cabal-files/extra.nix;
        haskell-src-meta.revision = import ./cabal-files/haskell-src-meta.nix;
        monad-control.revision = import ./cabal-files/monad-control.nix;
        bitvec.revision = import ./cabal-files/bitvec.nix;
        bitvec.flags.simd = true;
        random.revision = import ./cabal-files/random.nix;
        async.revision = import ./cabal-files/async.nix;
        async.flags.bench = false;
        async.flags.debug-auto-label = false;
        mtl-compat.revision = import ./cabal-files/mtl-compat.nix;
        mtl-compat.flags.two-point-one = false;
        mtl-compat.flags.two-point-two = false;
        text.revision = hackage.text."2.1.3".revisions.default;
        safe-exceptions.revision = import ./cabal-files/safe-exceptions.nix;
        time.revision = hackage.time."1.15".revisions.default;
        array.revision = hackage.array."0.5.8.0".revisions.default;
        terminal-size.revision = import ./cabal-files/terminal-size.nix;
        vector-algorithms.revision = import ./cabal-files/vector-algorithms.nix;
        vector-algorithms.flags.bench = true;
        vector-algorithms.flags.internalchecks = false;
        vector-algorithms.flags.boundschecks = true;
        vector-algorithms.flags.unsafechecks = false;
        vector-algorithms.flags.llvm = false;
        hinotify.revision = import ./cabal-files/hinotify.nix;
        network.revision = import ./cabal-files/network.nix;
        network.flags.devel = false;
        unliftio-core.revision = import ./cabal-files/unliftio-core.nix;
        resourcet.revision = import ./cabal-files/resourcet.nix;
        mono-traversable.revision = import ./cabal-files/mono-traversable.nix;
        microaeson.revision = import ./cabal-files/microaeson.nix;
        happy.revision = import ./cabal-files/happy.nix;
        hashable.revision = import ./cabal-files/hashable.nix;
        hashable.flags.random-initial-seed = false;
        hashable.flags.arch-native = false;
        th-compat.revision = import ./cabal-files/th-compat.nix;
        utf8-string.revision = import ./cabal-files/utf8-string.nix;
        syb.revision = import ./cabal-files/syb.nix;
        ghc-internal.revision = hackage.ghc-internal."9.1401.0".revisions.default;
        alex.revision = import ./cabal-files/alex.nix;
        conduit-extra.revision = import ./cabal-files/conduit-extra.nix;
        binary.revision = hackage.binary."0.8.9.3".revisions.default;
        monad-loops.revision = import ./cabal-files/monad-loops.nix;
        monad-loops.flags.base4 = true;
        template-haskell.revision = hackage.template-haskell."2.24.0.0".revisions.default;
        th-reify-many.revision = import ./cabal-files/th-reify-many.nix;
        unix.revision = hackage.unix."2.8.8.0".revisions.default;
        primitive.revision = import ./cabal-files/primitive.nix;
        ansi-terminal.revision = import ./cabal-files/ansi-terminal.nix;
        ansi-terminal.flags.example = false;
        hsc2hs.revision = import ./cabal-files/hsc2hs.nix;
        hsc2hs.flags.in-ghc-tree = false;
        colour.revision = import ./cabal-files/colour.nix;
        exceptions.revision = hackage.exceptions."0.10.11".revisions.default;
        retry.revision = import ./cabal-files/retry.nix;
        retry.flags.lib-werror = false;
        bytestring.revision = hackage.bytestring."0.12.2.0".revisions.default;
        cmdargs.revision = import ./cabal-files/cmdargs.nix;
        cmdargs.flags.testprog = false;
        cmdargs.flags.quotation = true;
        unliftio.revision = import ./cabal-files/unliftio.nix;
        integer-logarithms.revision = import ./cabal-files/integer-logarithms.nix;
        integer-logarithms.flags.integer-gmp = true;
        integer-logarithms.flags.check-bounds = false;
        text-conversions.revision = import ./cabal-files/text-conversions.nix;
        tagged.revision = import ./cabal-files/tagged.nix;
        tagged.flags.deepseq = true;
        ghc-boot-th.revision = hackage.ghc-boot-th."9.14.1".revisions.default;
        safe.revision = import ./cabal-files/safe.nix;
        os-string.revision = hackage.os-string."2.0.8".revisions.default;
        transformers-compat.revision = import ./cabal-files/transformers-compat.nix;
        transformers-compat.flags.three = false;
        transformers-compat.flags.four = false;
        transformers-compat.flags.five-three = true;
        transformers-compat.flags.mtl = true;
        transformers-compat.flags.generic-deriving = true;
        transformers-compat.flags.two = false;
        transformers-compat.flags.five = false;
        temporary.revision = import ./cabal-files/temporary.nix;
        prettyprinter.revision = import ./cabal-files/prettyprinter.nix;
        prettyprinter.flags.buildreadme = false;
        prettyprinter.flags.text = true;
        ghc-prim.revision = hackage.ghc-prim."0.13.1".revisions.default;
        happy-lib.revision = import ./cabal-files/happy-lib.nix;
        th-expand-syns.revision = import ./cabal-files/th-expand-syns.nix;
        ghcid.revision = import ./cabal-files/ghcid.nix;
        clock.revision = import ./cabal-files/clock.nix;
        clock.flags.llvm = false;
        pretty.revision = hackage.pretty."1.1.3.6".revisions.default;
        zlib.revision = import ./cabal-files/zlib.nix;
        zlib.flags.bundled-c-zlib = false;
        zlib.flags.non-blocking-ffi = true;
        zlib.flags.pkg-config = true;
        splitmix.revision = import ./cabal-files/splitmix.nix;
        splitmix.flags.optimised-mixer = false;
        containers.revision = hackage.containers."0.8".revisions.default;
        th-orphans.revision = import ./cabal-files/th-orphans.nix;
        prettyprinter-ansi-terminal.revision = import ./cabal-files/prettyprinter-ansi-terminal.nix;
        prettyprinter-ansi-terminal.flags.text = true;
        easy-file.revision = import ./cabal-files/easy-file.nix;
        scientific.revision = import ./cabal-files/scientific.nix;
        scientific.flags.integer-simple = false;
        vector.revision = import ./cabal-files/vector.nix;
        vector.flags.internalchecks = false;
        vector.flags.boundschecks = true;
        vector.flags.wall = false;
        vector.flags.unsafechecks = false;
        unix-compat.revision = import ./cabal-files/unix-compat.nix;
        rts.revision = hackage.rts."1.0.3".revisions.default;
        th-lift.revision = import ./cabal-files/th-lift.nix;
      };
      compiler = {
        version = "9.14.1";
        nix-name = "ghc9141";
        packages = {
          "ghc-boot-th" = "9.14.1";
          "binary" = "0.8.9.3";
          "pretty" = "1.1.3.6";
          "array" = "0.5.8.0";
          "time" = "1.15";
          "file-io" = "0.1.5";
          "ghc-prim" = "0.13.1";
          "bytestring" = "0.12.2.0";
          "process" = "1.6.26.1";
          "mtl" = "2.3.1";
          "text" = "2.1.3";
          "template-haskell" = "2.24.0.0";
          "ghc-bignum" = "1.4";
          "stm" = "2.5.3.1";
          "filepath" = "1.5.4.0";
          "os-string" = "2.0.8";
          "rts" = "1.0.3";
          "unix" = "2.8.8.0";
          "exceptions" = "0.10.11";
          "deepseq" = "1.5.1.0";
          "transformers" = "0.6.1.2";
          "containers" = "0.8";
          "ghc-internal" = "9.1401.0";
          "base" = "4.22.0.0";
          "directory" = "1.3.10.0";
        };
      };
    };
  extras = hackage:
    { packages = {}; };
  modules = [
    {
      preExistingPkgs = [
        "filepath"
        "ghc-bignum"
        "stm"
        "transformers"
        "deepseq"
        "directory"
        "file-io"
        "mtl"
        "process"
        "base"
        "text"
        "time"
        "array"
        "ghc-internal"
        "binary"
        "template-haskell"
        "unix"
        "exceptions"
        "bytestring"
        "ghc-boot-th"
        "os-string"
        "ghc-prim"
        "pretty"
        "containers"
        "rts"
      ];
    }
    ({ lib, ... }:
      { packages = {}; })
    ({ lib, ... }:
      {
        packages = {
          "alex".components.exes."alex".planned = lib.mkOverride 900 true;
          "monad-loops".components.library.planned = lib.mkOverride 900 true;
          "base64-bytestring".components.library.planned = lib.mkOverride 900 true;
          "file-io".components.library.planned = lib.mkOverride 900 true;
          "attoparsec".components.sublibs."attoparsec-internal".planned = lib.mkOverride 900 true;
          "resourcet".components.library.planned = lib.mkOverride 900 true;
          "monad-logger".components.library.planned = lib.mkOverride 900 true;
          "transformers-base".components.library.planned = lib.mkOverride 900 true;
          "mono-traversable".components.library.planned = lib.mkOverride 900 true;
          "conduit".components.library.planned = lib.mkOverride 900 true;
          "hashable".components.library.planned = lib.mkOverride 900 true;
          "fsnotify".components.library.planned = lib.mkOverride 900 true;
          "template-haskell".components.library.planned = lib.mkOverride 900 true;
          "easy-file".components.library.planned = lib.mkOverride 900 true;
          "unordered-containers".components.library.planned = lib.mkOverride 900 true;
          "transformers".components.library.planned = lib.mkOverride 900 true;
          "unliftio-core".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."tabular".planned = lib.mkOverride 900 true;
          "th-expand-syns".components.library.planned = lib.mkOverride 900 true;
          "scientific".components.library.planned = lib.mkOverride 900 true;
          "array".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."backend-glr".planned = lib.mkOverride 900 true;
          "unix".components.library.planned = lib.mkOverride 900 true;
          "base-orphans".components.library.planned = lib.mkOverride 900 true;
          "exceptions".components.library.planned = lib.mkOverride 900 true;
          "cryptohash-sha256".components.library.planned = lib.mkOverride 900 true;
          "unliftio".components.library.planned = lib.mkOverride 900 true;
          "retry".components.library.planned = lib.mkOverride 900 true;
          "directory".components.library.planned = lib.mkOverride 900 true;
          "syb".components.library.planned = lib.mkOverride 900 true;
          "extra".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."frontend".planned = lib.mkOverride 900 true;
          "lifted-base".components.library.planned = lib.mkOverride 900 true;
          "containers".components.library.planned = lib.mkOverride 900 true;
          "utf8-string".components.library.planned = lib.mkOverride 900 true;
          "monad-control".components.library.planned = lib.mkOverride 900 true;
          "random".components.library.planned = lib.mkOverride 900 true;
          "th-reify-many".components.library.planned = lib.mkOverride 900 true;
          "vector-algorithms".components.library.planned = lib.mkOverride 900 true;
          "prettyprinter".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.library.planned = lib.mkOverride 900 true;
          "transformers-compat".components.library.planned = lib.mkOverride 900 true;
          "fsnotify".components.exes."example".planned = lib.mkOverride 900 true;
          "conduit-extra".components.library.planned = lib.mkOverride 900 true;
          "typed-process".components.library.planned = lib.mkOverride 900 true;
          "auto-update".components.library.planned = lib.mkOverride 900 true;
          "safe-exceptions".components.library.planned = lib.mkOverride 900 true;
          "stm".components.library.planned = lib.mkOverride 900 true;
          "haskell-src-exts".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."grammar".planned = lib.mkOverride 900 true;
          "cmdargs".components.library.planned = lib.mkOverride 900 true;
          "rts".components.library.planned = lib.mkOverride 900 true;
          "network".components.library.planned = lib.mkOverride 900 true;
          "ghcid".components.library.planned = lib.mkOverride 900 true;
          "bytestring".components.library.planned = lib.mkOverride 900 true;
          "bitvec".components.library.planned = lib.mkOverride 900 true;
          "streaming-commons".components.library.planned = lib.mkOverride 900 true;
          "unix-compat".components.library.planned = lib.mkOverride 900 true;
          "attoparsec".components.library.planned = lib.mkOverride 900 true;
          "ghcid".components.exes."ghcid".planned = lib.mkOverride 900 true;
          "colour".components.library.planned = lib.mkOverride 900 true;
          "integer-logarithms".components.library.planned = lib.mkOverride 900 true;
          "deepseq".components.library.planned = lib.mkOverride 900 true;
          "haskell-src-meta".components.library.planned = lib.mkOverride 900 true;
          "optparse-applicative".components.library.planned = lib.mkOverride 900 true;
          "tagged".components.library.planned = lib.mkOverride 900 true;
          "zlib".components.library.planned = lib.mkOverride 900 true;
          "filepath".components.library.planned = lib.mkOverride 900 true;
          "happy".components.exes."happy".planned = lib.mkOverride 900 true;
          "ghc-internal".components.library.planned = lib.mkOverride 900 true;
          "time".components.library.planned = lib.mkOverride 900 true;
          "primitive".components.library.planned = lib.mkOverride 900 true;
          "ghc-bignum".components.library.planned = lib.mkOverride 900 true;
          "pretty".components.library.planned = lib.mkOverride 900 true;
          "th-compat".components.library.planned = lib.mkOverride 900 true;
          "th-orphans".components.library.planned = lib.mkOverride 900 true;
          "os-string".components.library.planned = lib.mkOverride 900 true;
          "split".components.library.planned = lib.mkOverride 900 true;
          "prettyprinter-ansi-terminal".components.library.planned = lib.mkOverride 900 true;
          "th-abstraction".components.library.planned = lib.mkOverride 900 true;
          "stm-chans".components.library.planned = lib.mkOverride 900 true;
          "safe".components.library.planned = lib.mkOverride 900 true;
          "mtl-compat".components.library.planned = lib.mkOverride 900 true;
          "fast-logger".components.library.planned = lib.mkOverride 900 true;
          "th-lift".components.library.planned = lib.mkOverride 900 true;
          "mtl".components.library.planned = lib.mkOverride 900 true;
          "vector".components.sublibs."benchmarks-O2".planned = lib.mkOverride 900 true;
          "binary".components.library.planned = lib.mkOverride 900 true;
          "ansi-terminal-types".components.library.planned = lib.mkOverride 900 true;
          "ghc-boot-th".components.library.planned = lib.mkOverride 900 true;
          "ansi-terminal".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."backend-lalr".planned = lib.mkOverride 900 true;
          "hsc2hs".components.exes."hsc2hs".planned = lib.mkOverride 900 true;
          "vector-stream".components.library.planned = lib.mkOverride 900 true;
          "text-conversions".components.library.planned = lib.mkOverride 900 true;
          "unix-time".components.library.planned = lib.mkOverride 900 true;
          "temporary".components.library.planned = lib.mkOverride 900 true;
          "base".components.library.planned = lib.mkOverride 900 true;
          "string-interpolate".components.library.planned = lib.mkOverride 900 true;
          "process".components.library.planned = lib.mkOverride 900 true;
          "hinotify".components.library.planned = lib.mkOverride 900 true;
          "vector".components.library.planned = lib.mkOverride 900 true;
          "microaeson".components.library.planned = lib.mkOverride 900 true;
          "terminal-size".components.library.planned = lib.mkOverride 900 true;
          "base16-bytestring".components.library.planned = lib.mkOverride 900 true;
          "tasty".components.library.planned = lib.mkOverride 900 true;
          "clock".components.library.planned = lib.mkOverride 900 true;
          "text".components.library.planned = lib.mkOverride 900 true;
          "splitmix".components.library.planned = lib.mkOverride 900 true;
          "ghc-prim".components.library.planned = lib.mkOverride 900 true;
          "async".components.library.planned = lib.mkOverride 900 true;
        };
      })
  ];
}