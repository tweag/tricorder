# Run Tests After Build — Work Package

## High-level Description

After a successful build (no compilation errors), automatically execute configured test
suites and report results alongside build status. Developers get immediate feedback on both
compilation and tests from a single `tricorder status` query, without a separate `cabal test`
invocation.

Tests run in short-lived `cabal repl test:<name>` sessions spawned after each clean build.
The first run after a cold cache compiles to interpreted bytecode; subsequent runs reuse the
cache and pay only GHCi startup overhead (~3s).

**Deliverables:**

- `testTargets` optional config field in `.tricorder.toml` to pin which suites to run
- Auto-discovery: when `testTargets` is absent, all `test:` components in `targets` are run
- `Testing` build phase visible in watch mode while suites are running
- Test results (pass / fail / error + output) stored in `BuildResult` and surfaced in
  `tricorder status` output
- Exit code of `tricorder status` reflects test failures alongside build errors

---

## Core Objectives

- Tests run automatically after every green build with no manual steps
- Auto-discovery means a single-suite project needs zero extra config — when `targets` is
  omitted entirely, all components (including test suites) are discovered from the cabal
  file automatically
- `testTargets = []` in `.tricorder.toml` opts a project out entirely; a project with no
  `test:` components in `targets` is also unaffected
- Test failures are clearly distinguished from compilation errors in output

---

## Metrics for Success

- After a green build, `tricorder status` shows pass/fail test summary
- GHCi-based test execution is noticeably faster than `cabal test` for incremental runs
- A project with no `test:` components in `targets` behaves identically to today

---

## Classification

- **New initiative or continuation of existing:** New initiative
- **Primary nature:** Technical

---

## Milestones

### Milestone 1 — Config & Type Plumbing

Add `testTargets :: Maybe [Text]` to `Config` and `testRuns :: [TestRun]` to
`BuildResult`. No runtime behavior change.

**Deliverables:**
- `TestRun` and `TestOutcome` types defined and JSON-serialisable
- `Config` loads `testTargets` from TOML
- `BuildResult` carries `testRuns :: [TestRun]`
- `resolveTestTargets` auto-discovers `test:` components from `targets` when `testTargets`
  is absent

**Acceptance criteria:**
- Config round-trips `.tricorder.toml` with `testTargets`
- Wire protocol is unchanged when no test suites are present (existing clients unaffected)

---

### Milestone 2 — Test Execution

After a successful build with no errors, spawn a short-lived `cabal repl test:<name>`
per suite, send `:main\n:quit\n`, capture output, and infer pass/fail.

**Deliverables:**
- `TestRunner` effect with `runTestSuite :: Text -> m TestRun` operation
- `GhciSession` listener transitions to `Testing` phase and runs suites after a clean build
- `BuildResult.testRuns` populated on completion; empty when build has errors

**Acceptance criteria:**
- Passing tests → `TestsPassed` in status output
- Failing tests → `TestsFailed` with captured output
- GHCi-level exception or timeout → `TestsError` with message
- `tricorder status` exit code is non-zero when tests fail

---

### Milestone 3 — Rendering & UX

Show test results clearly across all output modes.

**Deliverables:**
- `tricorder status` text output: one-line pass/fail per suite appended after build summary
- `tricorder status --verbose`: full test output included
- `tricorder watch`: live update shows `Testing…` while tests run, then result

**Acceptance criteria:**
- Concise default output; full output behind `--verbose`
- Test failure distinguishable from build error at a glance

---

## Notes

- When `targets` is omitted, all components are auto-discovered from the cabal file
  (including test suites), so tests run without any explicit config. To load only library
  components without running tests, either set `targets` explicitly to non-test components
  or set `testTargets = []` in `.tricorder.toml`.
- Builds with warnings but no errors still trigger test execution.
- See `design.md` for the rationale for separate test repls over in-session evaluation.
