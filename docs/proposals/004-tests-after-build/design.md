# Design: Run Tests After Build

## Status

Draft. See `README.md` for the work package. Low-level contracts in `spec.md`.

---

## Problem

After `tricorder` reports a clean build, the developer still has to separately run `cabal test`
to know whether their changes are correct. That invocation recompiles and relinks, adding
seconds to the feedback loop.

---

## Approach

### Separate short-lived test repl per suite

After each clean build, for each test suite to run, tricorder spawns a short-lived
`cabal repl test:<name>` process, sends `:main\n:quit\n`, captures stdout/stderr, then
exits. This approach was chosen after ruling out in-session evaluation (see below).

Each test repl maintains its own bytecode cache in `dist-newstyle`. The first run after a
cold cache compiles to interpreted bytecode (~3s total including startup); subsequent runs
reuse the cache and cost only startup overhead (~3s). The ~3s floor is irreducible GHCi
process startup and cabal plan resolution.

### Configuration

```toml
# No config needed for a single-suite project — auto-discovered from targets
targets = ["lib:mylib", "test:mylib-test"]

# Monorepo: load everything but only run one suite
targets = ["lib:atelier", "test:atelier-test", "lib:tricorder", "test:tricorder-test"]
test_targets = ["test:tricorder-test"]
```

`testTargets` is an optional list of `test:<name>` components. When absent, all `test:`
components in `targets` are run. When present, only the listed suites are run.

### Entry point

We always invoke `:main` in the test repl — GHCi's built-in command that respects the
`-main-is` setting of the loaded component. The cabal file does not need to be parsed
for the entry point at runtime; GHCi already knows it.

The cabal file is parsed only to discover *which* test suites exist and to populate
`testTargets` auto-discovery — not to determine the expression to evaluate.

### Pass/fail detection

All major test frameworks (`hspec`, `tasty`, `HUnit`) call `System.Exit.exitWith` on
completion. GHCi surfaces this as:

```
*** Exception: ExitSuccess    -- pass
*** Exception: ExitFailure 1  -- fail
```

Detection: scan output for `*** Exception: ExitSuccess` (pass) or
`*** Exception: ExitFailure` (fail). Any other `*** Exception:` is an error (runner
crashed). Absence of an exception line is treated as pass.

### New build phase

`BuildPhase` gains a `Testing` constructor:

```haskell
data BuildPhase = Building | Testing | Done BuildResult
```

The daemon transitions to `Testing` after a clean build, runs the test repls sequentially,
then transitions to `Done` with results attached.

### Results in `BuildResult`

```haskell
data BuildResult = BuildResult
  { ...
  , testRuns :: [TestRun]   -- empty when no test suites in targets, or build had errors
  }

data TestRun = TestRun
  { target  :: Text         -- "test:tricorder-test"
  , outcome :: TestOutcome
  , output  :: Text         -- captured stdout+stderr
  }

data TestOutcome = TestsPassed | TestsFailed | TestsError Text
```

---

## Why Not In-Session Evaluation

The natural first idea is to evaluate the test entry point inside the already-running
multi-repl GHCi session, avoiding a second process entirely. This was investigated and
ruled out for fundamental reasons:

**Home unit modules are inaccessible in the multi-repl interactive context.** GHCi
multi-mode does not expose any home unit module to the evaluator by default. `:module` is
explicitly unsupported (`Command is not supported (yet) in multi-mode`). There is no way
to bring `Main` or any other test module into scope — regardless of naming scheme,
`-XPackageImports`, or `-main-is` tricks. The limitation is in the GHCi multi-mode
implementation, not in our design.

**Session cloning is not viable.** OS `fork()` is unsafe on a multi-threaded Haskell RTS.
CRIU requires elevated privileges and breaks on open sockets.

**Artifact sharing between the multi-repl and a separate test repl is not possible.**
Different flag fingerprints (unit-id, linking flags) cause `[Flags changed]` on the first
run; the two sessions maintain separate bytecode caches permanently.

---

## Alternatives Considered

### `cabal test`

Full rebuild + relink on every run. Slower than a fresh test repl by the link step and
cabal's separate build profile. Rejected for speed.

### Keep main session as single-target (no multi-repl)

Would enable in-session eval. Rejected — loses the core value of fast multi-package
incremental builds.

### Persistent per-suite GHCi session

Keep a long-lived `cabal repl test:<name>` running alongside the main session and send
`:reload` + `:main` after each clean build. This would eliminate the ~3s startup per test
run at the cost of memory (one extra GHCi process per suite).

This is a noteworthy avenue for a follow-on. GHC's built-in Prometheus metrics (RTS
memory stats) would give concrete resident-memory figures per session, and the daemon can
emit test latency metrics alongside them. That data would make the trade-off concrete
rather than estimated.

---

## Trade-offs

- **~3s per test suite** — startup-dominated, not recompilation-dominated. Acceptable for
  post-build feedback; faster than `cabal test`.
- **Sequential execution** — test suites run one at a time; parallel runs possible in future.
- **Tests skip on build errors** — no test run is attempted when the build has any errors.
- **No timeout** — a hung test suite blocks the daemon indefinitely. A configurable timeout
  is a candidate for a follow-on.

---

## Open Questions

1. ~~Should `tricorder status --wait` block until tests complete (build + tests) or just until
   the build completes?~~ Resolved: `--wait` blocks through the `Testing` phase to `Done`,
   so it always returns the full build + test result.
2. Is a persistent per-suite session worth the memory cost? Revisit once basic approach
   ships and we have real usage data.
