# Research: Run Tests After Build

## Auto-Discovery of Test Entry Points from Cabal Metadata

### The Cabal API already parses everything we need

`Config.hs` already imports `Distribution.Types.TestSuite` and uses `condTestSuites`.
The `TestSuite` record has a `testInterface` field:

```haskell
data TestSuiteInterface
  = TestSuiteExeV10 Version FilePath   -- exitcode-stdio-1.0; FilePath is main-is
  | TestSuiteLibV09 Version ModuleName -- detailed-0.9 (rare)
  | TestSuiteUnsupported TestType
```

For `exitcode-stdio-1.0` (virtually all modern test suites), `TestSuiteExeV10` hands us
the `main-is` filepath directly — no regex parsing required.

**Source:** `Distribution.Types.TestSuiteInterface`; `Distribution.Types.TestSuite`

### Framework detection is unnecessary

From reading `Test.Hspec` and `Test.Tasty` sources via `tricorder source`:

- HSpec: `hspec :: Spec -> IO ()` — user's `main` calls `hspec spec`
- Tasty: `defaultMain :: TestTree -> IO ()` — user's `main` calls `defaultMain tests`

Both ultimately call `exitWith`/`exitFailure` from `main`. The expression to run is always
`main` regardless of framework.

### The `-main-is` GHC option breaks the `Main.main` assumption

The `ghc-options` field in a `test-suite` stanza can override which module and function
serve as the entry point:

```cabal
-- ghcid's own test suite:
test-suite ghcid_test
    type:            exitcode-stdio-1.0
    main-is:         Test.hs
    ghc-options:     -main-is Test.main
```

Here the entry point is `Test.main`, not `Main.main`. Without parsing `-main-is`, we'd
invoke the wrong function.

GHC options live in `BuildInfo.options :: PerCompilerFlavor [String]`, extracted via
`hcOptions GHC bi`. We scan the resulting `[String]` for a `-main-is` flag (either as a
separate token followed by the qualified name, or combined as `"-main-is Foo.bar"`).

---

## Multi-REPL: In-Session Eval is a Dead End

### Home unit modules are not accessible in the multi-repl interactive context

In a `cabal repl --enable-multi-repl` session, the interactive evaluator has no access to
any home unit module by default. Verified empirically:

```
ghci> main
<interactive>:1:1: error: [GHC-88464]
    Variable not in scope: main
```

`:module *Main` — the normal way to bring a `Main` into scope — is explicitly unsupported:

```
ghci> :module *Main
Command is not supported (yet) in multi-mode
```

This applies even when only a single test suite is loaded alongside a library. As soon as
`--enable-multi-repl` is used with more than one home unit, the interactive context is
isolated from all of them.

**Consequence:** evaluating a test entry point inside the main tricorder GHCi session is not
possible. Any `-main-is` naming trick or module qualification scheme is irrelevant — the
module simply cannot be reached.

### `-XPackageImports` does not apply

Test suite components are home units, not packages in the package database. They do not
appear in `:show packages` output. Package-qualified import syntax (`import "pkg" Module`)
only works for database packages, not home units.

---

## Separate-Process Approach: Artifact Sharing and Timing

### The approach

After each clean build, spawn a short-lived `cabal repl test:<name>` process, send `:main`,
collect output, then exit. This sidesteps the multi-repl eval problem entirely.

### Does the separate repl recompile from scratch?

**First run after switching build flavor:** yes, full recompile. Observed when switching
from a plain multi-repl session to a single-target repl — all 14 modules recompiled with
`[Flags changed]`.

**Subsequent runs (same flavor):** no recompilation. GHCi reuses interpreted bytecode from
the previous single-target repl run. Verified by touching a source file — the run still
showed `Ok, 13 modules loaded` with no compilation lines, using cached bytecode.

**With `-fobject-code` on the multi-repl session:** writes `.o` files to the same
`dist-newstyle` paths that a single-target repl uses, but the first single-target run still
shows `[Flags changed]` and recompiles. The unit-id and flag fingerprints differ between
multi-repl and single-target, so their artifacts are not compatible.

**Conclusion:** artifact sharing between the multi-repl and the test repl is not feasible.
The test repl maintains its own bytecode cache. After the first run it reuses that cache
efficiently.

### Timing (measured on tricorder/test:tricorder-test, 117 tests)

| Scenario | Time |
|----------|------|
| First run (cold bytecode cache) | ~3s |
| Subsequent run, no source changes | ~3s |
| After touching one test file | ~3s |

All ~3s is GHCi/cabal startup overhead. Recompilation cost is negligible (single changed
module recompiles in <0.1s, absorbed into startup noise). Test execution itself is 0.31s.

**The ~3s floor is irreducible** — it's process startup, cabal plan resolution, and GHCi
initialisation. This is acceptable for a post-build test run.

### Session cloning is not viable

- **OS `fork()`**: unsafe on a multi-threaded Haskell RTS process.
- **CRIU snapshot/restore**: requires elevated privileges (`CAP_SYS_PTRACE`), breaks on
  open sockets (which ghcid holds), and is operationally complex.
- Neither is practical.

---

## Multiple Test Suites and `testTargets`

### The tricorder repo is a concrete collision case

Both `test:atelier-test` and `test:tricorder-test` use `main-is: Driver.hs` with no `-main-is`
override — both produce a `Main` module. This is representative of monorepo projects.

### Design: auto-discover with optional `testTargets` filter

- **Default:** discover all `test:` components in `targets`, run each in its own `cabal
  repl` process sequentially after a clean build.
- **`testTargets` config field:** optional list of `test:<name>` components to run. When
  set, only those suites are run regardless of what else is in `targets`. Allows narrowing
  in a monorepo without changing the build targets.
- **No collision problem:** each test suite runs in its own single-target repl process,
  so there is no module ambiguity. The multi-repl ambiguity issue is entirely avoided.

```toml
# Run all test suites in targets (default — no config needed for single-suite projects)
targets = ["lib:mylib", "test:mylib-test"]

# Monorepo: load everything but only run one suite
targets = ["lib:atelier", "test:atelier-test", "lib:tricorder", "test:tricorder-test"]
test_targets = ["test:tricorder-test"]
```

---

## Pass/Fail Detection

Standard Haskell test frameworks signal failure via `System.Exit.exitFailure`, which GHCi
surfaces as:

```
*** Exception: ExitFailure 1
```

Observed in a real run:

```
All 117 tests passed (0.31s)
*** Exception: ExitSuccess
```

Both pass and fail go through `exitWith`. Detection heuristic:

- `*** Exception: ExitSuccess` → **pass**
- `*** Exception: ExitFailure N` → **fail**
- Any other `*** Exception:` → **error** (runner crashed)
- No exception line (e.g. runner called `exitSuccess` then process ended) → treat as **pass**

This covers HSpec, Tasty, HUnit, and any runner that calls `exitWith`. Runners that
indicate failure only via output text (without `exitFailure`) are not covered, but none of
the major frameworks do this.

---

## Summary of Findings

| Question | Finding |
|----------|---------|
| Can we eval expressions in the multi-repl session? | **No** — home unit modules are inaccessible in multi-mode interactive context; `:module` unsupported |
| Can `-XPackageImports` or `-main-is` naming help? | No — home units are not in the package database; naming tricks are irrelevant |
| Can we clone the GHCi session? | No — fork is unsafe, CRIU is impractical |
| Can artifacts be shared between multi-repl and test repl? | No — different flag fingerprints cause `[Flags changed]` rebuild on first run |
| How fast is a separate single-target test repl? | ~3s total (startup-dominated); effectively free after first run |
| Framework detection needed? | No — all frameworks go through `main`/`exitWith` |
| Can we auto-discover the entry point? | Not needed — `:main` in the test repl resolves the entry point via GHCi's built-in `-main-is` handling; no cabal parsing required at runtime |
| How to handle multiple test suites? | Run each in its own process; `testTargets` filters which ones |
| Pass/fail detection | `*** Exception: ExitSuccess/ExitFailure` pattern; covers all major frameworks |
