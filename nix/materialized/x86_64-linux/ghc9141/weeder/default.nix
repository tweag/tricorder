{
  pkgs = hackage:
    {
      packages = {
        ghc-boot.revision = hackage.ghc-boot."9.14.1".revisions.default;
        filepath.revision = hackage.filepath."1.5.4.0".revisions.default;
        semaphore-compat.revision = hackage.semaphore-compat."1.0.0".revisions.default;
        invariant.revision = import ./cabal-files/invariant.nix;
        generic-lens-core.revision = import ./cabal-files/generic-lens-core.nix;
        unordered-containers.revision = import ./cabal-files/unordered-containers.nix;
        unordered-containers.flags.debug = false;
        case-insensitive.revision = import ./cabal-files/case-insensitive.nix;
        transformers-base.revision = import ./cabal-files/transformers-base.nix;
        transformers-base.flags.orphaninstances = true;
        OneTuple.revision = import ./cabal-files/OneTuple.nix;
        OneTuple.flags.base-ge-4-15 = true;
        OneTuple.flags.base-ge-4-16 = true;
        tasty.revision = import ./cabal-files/tasty.nix;
        tasty.flags.terminal-size = true;
        tasty.flags.unix = true;
        ghc.revision = hackage.ghc."9.14.1".revisions.default;
        ghc-heap.revision = hackage.ghc-heap."9.14.1".revisions.default;
        vector-stream.revision = import ./cabal-files/vector-stream.nix;
        weeder.revision = import ./cabal-files/weeder.nix;
        comonad.revision = import ./cabal-files/comonad.nix;
        comonad.flags.containers = true;
        comonad.flags.indexed-traversable = true;
        comonad.flags.distributive = true;
        stm.revision = hackage.stm."2.5.3.1".revisions.default;
        transformers.revision = hackage.transformers."0.6.1.2".revisions.default;
        distributive.revision = import ./cabal-files/distributive.nix;
        distributive.flags.tagged = true;
        deepseq.revision = hackage.deepseq."1.5.1.0".revisions.default;
        optparse-applicative.revision = import ./cabal-files/optparse-applicative.nix;
        optparse-applicative.flags.process = true;
        directory.revision = hackage.directory."1.3.10.0".revisions.default;
        ghci.revision = hackage.ghci."9.14.1".revisions.default;
        file-io.revision = hackage.file-io."0.1.5".revisions.default;
        kan-extensions.revision = import ./cabal-files/kan-extensions.nix;
        parsec.revision = hackage.parsec."3.1.18.0".revisions.default;
        strict.revision = import ./cabal-files/strict.nix;
        generic-lens.revision = import ./cabal-files/generic-lens.nix;
        th-abstraction.revision = import ./cabal-files/th-abstraction.nix;
        profunctors.revision = import ./cabal-files/profunctors.nix;
        adjunctions.revision = import ./cabal-files/adjunctions.nix;
        algebraic-graphs.revision = import ./cabal-files/algebraic-graphs.nix;
        parser-combinators.revision = import ./cabal-files/parser-combinators.nix;
        parser-combinators.flags.dev = false;
        mtl.revision = hackage.mtl."2.3.1".revisions.default;
        ansi-terminal-types.revision = import ./cabal-files/ansi-terminal-types.nix;
        process.revision = hackage.process."1.6.26.1".revisions.default;
        base.revision = hackage.base."4.22.0.0".revisions.default;
        call-stack.revision = import ./cabal-files/call-stack.nix;
        base-orphans.revision = import ./cabal-files/base-orphans.nix;
        indexed-profunctors.revision = import ./cabal-files/indexed-profunctors.nix;
        toml-reader.revision = import ./cabal-files/toml-reader.nix;
        indexed-traversable-instances.revision = import ./cabal-files/indexed-traversable-instances.nix;
        these.revision = import ./cabal-files/these.nix;
        random.revision = import ./cabal-files/random.nix;
        async.revision = import ./cabal-files/async.nix;
        async.flags.bench = false;
        async.flags.debug-auto-label = false;
        bifunctors.revision = import ./cabal-files/bifunctors.nix;
        bifunctors.flags.tagged = true;
        text.revision = hackage.text."2.1.3".revisions.default;
        time.revision = hackage.time."1.15".revisions.default;
        array.revision = hackage.array."0.5.8.0".revisions.default;
        terminal-size.revision = import ./cabal-files/terminal-size.nix;
        semigroupoids.revision = import ./cabal-files/semigroupoids.nix;
        semigroupoids.flags.unordered-containers = true;
        semigroupoids.flags.containers = true;
        semigroupoids.flags.comonad = true;
        semigroupoids.flags.tagged = true;
        semigroupoids.flags.contravariant = true;
        contravariant.revision = import ./cabal-files/contravariant.nix;
        contravariant.flags.statevar = true;
        StateVar.revision = import ./cabal-files/StateVar.nix;
        megaparsec.revision = import ./cabal-files/megaparsec.nix;
        megaparsec.flags.dev = false;
        indexed-traversable.revision = import ./cabal-files/indexed-traversable.nix;
        indexed-traversable.flags.base-ge-4-18 = true;
        hashable.revision = import ./cabal-files/hashable.nix;
        hashable.flags.random-initial-seed = false;
        hashable.flags.arch-native = false;
        hpc.revision = hackage.hpc."0.7.0.2".revisions.default;
        ghc-internal.revision = hackage.ghc-internal."9.1401.0".revisions.default;
        binary.revision = hackage.binary."0.8.9.3".revisions.default;
        free.revision = import ./cabal-files/free.nix;
        template-haskell.revision = hackage.template-haskell."2.24.0.0".revisions.default;
        unix.revision = hackage.unix."2.8.8.0".revisions.default;
        primitive.revision = import ./cabal-files/primitive.nix;
        ansi-terminal.revision = import ./cabal-files/ansi-terminal.nix;
        ansi-terminal.flags.example = false;
        hsc2hs.revision = import ./cabal-files/hsc2hs.nix;
        hsc2hs.flags.in-ghc-tree = false;
        colour.revision = import ./cabal-files/colour.nix;
        exceptions.revision = hackage.exceptions."0.10.11".revisions.default;
        bytestring.revision = hackage.bytestring."0.12.2.0".revisions.default;
        regex-base.revision = import ./cabal-files/regex-base.nix;
        reflection.revision = import ./cabal-files/reflection.nix;
        reflection.flags.template-haskell = true;
        reflection.flags.slow = false;
        ghc-platform.revision = hackage.ghc-platform."0.1.0.0".revisions.default;
        integer-logarithms.revision = import ./cabal-files/integer-logarithms.nix;
        integer-logarithms.flags.integer-gmp = true;
        integer-logarithms.flags.check-bounds = false;
        tagged.revision = import ./cabal-files/tagged.nix;
        tagged.flags.template-haskell = true;
        tagged.flags.deepseq = true;
        ghc-boot-th.revision = hackage.ghc-boot-th."9.14.1".revisions.default;
        Glob.revision = import ./cabal-files/Glob.nix;
        os-string.revision = hackage.os-string."2.0.8".revisions.default;
        transformers-compat.revision = import ./cabal-files/transformers-compat.nix;
        transformers-compat.flags.five-three = true;
        transformers-compat.flags.mtl = true;
        transformers-compat.flags.generic-deriving = true;
        transformers-compat.flags.five = false;
        prettyprinter.revision = import ./cabal-files/prettyprinter.nix;
        prettyprinter.flags.buildreadme = false;
        prettyprinter.flags.text = true;
        assoc.revision = import ./cabal-files/assoc.nix;
        assoc.flags.tagged = false;
        ghc-prim.revision = hackage.ghc-prim."0.13.1".revisions.default;
        pretty.revision = hackage.pretty."1.1.3.6".revisions.default;
        regex-tdfa.revision = import ./cabal-files/regex-tdfa.nix;
        regex-tdfa.flags.force-o2 = false;
        regex-tdfa.flags.doctest = true;
        splitmix.revision = import ./cabal-files/splitmix.nix;
        splitmix.flags.optimised-mixer = false;
        containers.revision = hackage.containers."0.8".revisions.default;
        prettyprinter-ansi-terminal.revision = import ./cabal-files/prettyprinter-ansi-terminal.nix;
        prettyprinter-ansi-terminal.flags.text = true;
        scientific.revision = import ./cabal-files/scientific.nix;
        scientific.flags.integer-simple = false;
        vector.revision = import ./cabal-files/vector.nix;
        vector.flags.internalchecks = false;
        vector.flags.boundschecks = true;
        vector.flags.wall = false;
        vector.flags.unsafechecks = false;
        rts.revision = hackage.rts."1.0.3".revisions.default;
        lens.revision = import ./cabal-files/lens.nix;
        lens.flags.inlining = true;
        lens.flags.test-properties = true;
        lens.flags.dump-splices = false;
        lens.flags.benchmark-uniplate = false;
        lens.flags.trustworthy = true;
        lens.flags.test-templates = true;
        lens.flags.j = false;
        lens.flags.test-hunit = true;
        dlist.revision = import ./cabal-files/dlist.nix;
        dlist.flags.werror = false;
        parallel.revision = import ./cabal-files/parallel.nix;
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
          "ghci" = "9.14.1";
          "mtl" = "2.3.1";
          "text" = "2.1.3";
          "template-haskell" = "2.24.0.0";
          "semaphore-compat" = "1.0.0";
          "parsec" = "3.1.18.0";
          "stm" = "2.5.3.1";
          "filepath" = "1.5.4.0";
          "os-string" = "2.0.8";
          "rts" = "1.0.3";
          "unix" = "2.8.8.0";
          "ghc-platform" = "0.1.0.0";
          "ghc" = "9.14.1";
          "ghc-boot" = "9.14.1";
          "hpc" = "0.7.0.2";
          "exceptions" = "0.10.11";
          "deepseq" = "1.5.1.0";
          "transformers" = "0.6.1.2";
          "containers" = "0.8";
          "ghc-internal" = "9.1401.0";
          "base" = "4.22.0.0";
          "ghc-heap" = "9.14.1";
          "directory" = "1.3.10.0";
        };
      };
    };
  extras = hackage:
    { packages = {}; };
  modules = [
    {
      preExistingPkgs = [
        "ghc-boot"
        "filepath"
        "semaphore-compat"
        "ghc"
        "ghc-heap"
        "stm"
        "transformers"
        "deepseq"
        "directory"
        "ghci"
        "file-io"
        "parsec"
        "mtl"
        "process"
        "base"
        "text"
        "time"
        "array"
        "hpc"
        "ghc-internal"
        "binary"
        "template-haskell"
        "unix"
        "exceptions"
        "bytestring"
        "ghc-platform"
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
          "adjunctions".components.library.planned = lib.mkOverride 900 true;
          "generic-lens".components.library.planned = lib.mkOverride 900 true;
          "generic-lens-core".components.library.planned = lib.mkOverride 900 true;
          "semaphore-compat".components.library.planned = lib.mkOverride 900 true;
          "file-io".components.library.planned = lib.mkOverride 900 true;
          "transformers-base".components.library.planned = lib.mkOverride 900 true;
          "hashable".components.library.planned = lib.mkOverride 900 true;
          "template-haskell".components.library.planned = lib.mkOverride 900 true;
          "parser-combinators".components.library.planned = lib.mkOverride 900 true;
          "unordered-containers".components.library.planned = lib.mkOverride 900 true;
          "these".components.library.planned = lib.mkOverride 900 true;
          "weeder".components.library.planned = lib.mkOverride 900 true;
          "distributive".components.library.planned = lib.mkOverride 900 true;
          "transformers".components.library.planned = lib.mkOverride 900 true;
          "case-insensitive".components.library.planned = lib.mkOverride 900 true;
          "profunctors".components.library.planned = lib.mkOverride 900 true;
          "Glob".components.library.planned = lib.mkOverride 900 true;
          "scientific".components.library.planned = lib.mkOverride 900 true;
          "array".components.library.planned = lib.mkOverride 900 true;
          "unix".components.library.planned = lib.mkOverride 900 true;
          "base-orphans".components.library.planned = lib.mkOverride 900 true;
          "call-stack".components.library.planned = lib.mkOverride 900 true;
          "exceptions".components.library.planned = lib.mkOverride 900 true;
          "directory".components.library.planned = lib.mkOverride 900 true;
          "semigroupoids".components.library.planned = lib.mkOverride 900 true;
          "indexed-traversable-instances".components.library.planned = lib.mkOverride 900 true;
          "indexed-profunctors".components.library.planned = lib.mkOverride 900 true;
          "containers".components.library.planned = lib.mkOverride 900 true;
          "parsec".components.library.planned = lib.mkOverride 900 true;
          "random".components.library.planned = lib.mkOverride 900 true;
          "invariant".components.library.planned = lib.mkOverride 900 true;
          "dlist".components.library.planned = lib.mkOverride 900 true;
          "hpc".components.library.planned = lib.mkOverride 900 true;
          "algebraic-graphs".components.library.planned = lib.mkOverride 900 true;
          "ghc".components.library.planned = lib.mkOverride 900 true;
          "prettyprinter".components.library.planned = lib.mkOverride 900 true;
          "megaparsec".components.library.planned = lib.mkOverride 900 true;
          "transformers-compat".components.library.planned = lib.mkOverride 900 true;
          "weeder".components.exes."weeder".planned = lib.mkOverride 900 true;
          "parallel".components.library.planned = lib.mkOverride 900 true;
          "StateVar".components.library.planned = lib.mkOverride 900 true;
          "stm".components.library.planned = lib.mkOverride 900 true;
          "strict".components.library.planned = lib.mkOverride 900 true;
          "rts".components.library.planned = lib.mkOverride 900 true;
          "comonad".components.library.planned = lib.mkOverride 900 true;
          "bytestring".components.library.planned = lib.mkOverride 900 true;
          "colour".components.library.planned = lib.mkOverride 900 true;
          "integer-logarithms".components.library.planned = lib.mkOverride 900 true;
          "free".components.library.planned = lib.mkOverride 900 true;
          "deepseq".components.library.planned = lib.mkOverride 900 true;
          "optparse-applicative".components.library.planned = lib.mkOverride 900 true;
          "tagged".components.library.planned = lib.mkOverride 900 true;
          "filepath".components.library.planned = lib.mkOverride 900 true;
          "assoc".components.library.planned = lib.mkOverride 900 true;
          "OneTuple".components.library.planned = lib.mkOverride 900 true;
          "regex-base".components.library.planned = lib.mkOverride 900 true;
          "toml-reader".components.library.planned = lib.mkOverride 900 true;
          "ghc-internal".components.library.planned = lib.mkOverride 900 true;
          "time".components.library.planned = lib.mkOverride 900 true;
          "primitive".components.library.planned = lib.mkOverride 900 true;
          "pretty".components.library.planned = lib.mkOverride 900 true;
          "lens".components.library.planned = lib.mkOverride 900 true;
          "reflection".components.library.planned = lib.mkOverride 900 true;
          "os-string".components.library.planned = lib.mkOverride 900 true;
          "prettyprinter-ansi-terminal".components.library.planned = lib.mkOverride 900 true;
          "kan-extensions".components.library.planned = lib.mkOverride 900 true;
          "th-abstraction".components.library.planned = lib.mkOverride 900 true;
          "regex-tdfa".components.library.planned = lib.mkOverride 900 true;
          "ghc-heap".components.library.planned = lib.mkOverride 900 true;
          "mtl".components.library.planned = lib.mkOverride 900 true;
          "bifunctors".components.library.planned = lib.mkOverride 900 true;
          "vector".components.sublibs."benchmarks-O2".planned = lib.mkOverride 900 true;
          "binary".components.library.planned = lib.mkOverride 900 true;
          "ansi-terminal-types".components.library.planned = lib.mkOverride 900 true;
          "ghci".components.library.planned = lib.mkOverride 900 true;
          "ghc-boot-th".components.library.planned = lib.mkOverride 900 true;
          "ansi-terminal".components.library.planned = lib.mkOverride 900 true;
          "hsc2hs".components.exes."hsc2hs".planned = lib.mkOverride 900 true;
          "vector-stream".components.library.planned = lib.mkOverride 900 true;
          "ghc-platform".components.library.planned = lib.mkOverride 900 true;
          "base".components.library.planned = lib.mkOverride 900 true;
          "process".components.library.planned = lib.mkOverride 900 true;
          "vector".components.library.planned = lib.mkOverride 900 true;
          "contravariant".components.library.planned = lib.mkOverride 900 true;
          "terminal-size".components.library.planned = lib.mkOverride 900 true;
          "tasty".components.library.planned = lib.mkOverride 900 true;
          "text".components.library.planned = lib.mkOverride 900 true;
          "indexed-traversable".components.library.planned = lib.mkOverride 900 true;
          "splitmix".components.library.planned = lib.mkOverride 900 true;
          "ghc-prim".components.library.planned = lib.mkOverride 900 true;
          "async".components.library.planned = lib.mkOverride 900 true;
          "ghc-boot".components.library.planned = lib.mkOverride 900 true;
        };
      })
  ];
}