---
name: tricorder
description: Check GHCi build status using the tricorder daemon. Use when asked to check the build, see compiler errors/warnings, or run tricorder.
user-invocable: true
allowed-tools: Bash(tricorder *)
---

# Using tricorder to Check Build Status

tricorder is a daemon-based GHCi build monitor. It exposes build state over a Unix socket and outputs human-readable text by default, or JSON with `--json` for tool integration.

## Commands

- `tricorder start` — start the daemon (no-op if already running)
- `tricorder stop` — stop the daemon, waiting for pending queries before quitting
- `tricorder stop --force` -- stop the daemon, ignoring pending queries
- `tricorder status` — print current build state as text
- `tricorder restart` -- restart the daemon, waiting for pending queries before shutting down
- `tricorder restart --force` -- restart the daemon, ignoring pending queries
- `tricorder status --wait` — same, but blocks until the current build cycle finishes
- `tricorder status --json` — output full build state as JSON
- `tricorder status --wait --json` — wait then output JSON
- `tricorder status --verbose` / `-v` — print full GHC message body under each diagnostic
- `tricorder status --expand <N>` — print the summary line and full GHC message body for diagnostic #N
- `tricorder test-results` — show full output from the latest test run
- `tricorder test-results --failed` — show output only from failed test suites
- `tricorder test-results --wait` — block until the current build cycle completes, then show results
- `tricorder source MODULE...` — print Haskell source for one or more installed modules (e.g. `tricorder source Data.Map.Strict`)
- `tricorder eval-comments` — print eval comments and their evaluated results from the current build result.
- `tricorder eval-comments --wait` — print eval comments and their evaluated results, waiting for the current build to finish if it is in-progress
- `tricorder eval-comments --json` — print eval comments and their evaluated results as JSON
- `tricorder eval-comments --wait --json` — print eval comments and their evaluated results as JSON, waiting for the current build to finish if it is in-progress
- `tricorder ui` — auto-refreshing terminal display (for humans)

## Checking Build Status

Run `tricorder status --wait` after making edits. The `--wait` flag ensures you get the result of the build triggered by your changes, not a stale one.

If `tricorder status` returns `Stopped.`, start the daemon with `tricorder start`.

### Text output (default)

One line per diagnostic (prefixed with a 1-based index), followed by a summary:

```
[1] E src/Foo/Bar.hs:42 `something` not in scope
[2] W src/Foo/Bar.hs:10 redundant import
2 error(s), 1 warning(s) (71 modules, 1.2s)
```

Format: `[N] <E|W> <file>:<line> <title>`

A clean build prints:

```
All good. (71 modules, 17.3s)
```

If test suites are configured, their results follow the build summary:

```
All good. (71 modules, 17.3s)
test:my-test  passed
test:other-test  failed
```

With `--wait`, if a build is in progress `Building...` is printed immediately before blocking.

With `--verbose`, the full GHC message body is printed under each diagnostic:

```
[1] E src/Foo/Bar.hs:42 `something` not in scope
Variable not in scope: something
    suggested fix: ...
1 error(s), 0 warning(s) (71 modules, 1.2s)
```

With `--expand <N>`, only diagnostic #N is expanded (summary line + full body):

```
[1] E src/Foo/Bar.hs:42 `something` not in scope
Variable not in scope: something
    suggested fix: ...
```

**Exit code**: 1 when any errors are present or any test suite fails, 0 otherwise (warnings alone → 0).

### JSON output (`--json`)

Use `--json` when you need structured data for further processing:

```json
{
  "buildId": 3,
  "phase": {
    "tag": "Done",
    "contents": {
      "completedAt": "2026-03-30T12:00:00Z",
      "durationMs": 420,
      "moduleCount": 42,
      "diagnostics": [...]
    }
  },
  "daemonInfo": { "targets": [], "watchDirs": [...], "sockPath": "...", "logFile": null }
}
```

Each diagnostic in `diagnostics`:

```json
{
  "severity": "error",
  "file": "src/Foo.hs",
  "line": 42,
  "col": 5,
  "endLine": 42,
  "endCol": 20,
  "title": "Variable not in scope: foo",
  "text": "Variable not in scope: foo\n    ...\n"
}
```

- `title` is the short summary (first line of the GHC message)
- `text` contains the full GHC message body

### Test results (`test-results`)

The daemon runs configured test suites automatically after each clean build — **never run `cabal test` manually**. Use `tricorder test-results` to inspect what happened.

Default output lists each suite with its outcome followed by full captured output:

```
test:my-tests  failed
  <full test runner output>
test:other-tests  passed
  <full test runner output>
```

With `--failed`, only failing suites are shown. If all suites passed:

```
All passed.
  test:my-tests
  test:other-tests
```

With `--wait`, blocks until the current build and test cycle completes before printing results. Combine with `--failed` to get a compact failure report after editing:

```
tricorder test-results --wait --failed
```

**Exit code**: 1 when any shown test suite failed or errored, 0 otherwise.

### Eval comments (`eval-comments`)

The daemon evaluates eval comments in the watched source files it finds. These
could be useful to you to run quick tests or for checking things.

Default output lists each eval comment with its evaluated result:

```
./src/Source/Module.hs (line 123)
Expression:
:t someFunc
Output:
someFunc :: Int -> Int
```

With `--json`, the output is formatted as a JSON object:

```
{
  "state": "done",
  "comments": [
    {
      "expression": ":t someFunc",
      "file": "./src/Source/Module.hs",
      "line": 123,
      "state": {
        "output": "someFunc :: Int -> Int\n\n",
        "state": "completed"
      }
    }
  ]
}
```

The `state` property on the top-level object represents the current build
state. If a build is currently in-progress, the `state` will show which stage
of the build the daemon is at. Only `done` will be accompanied by a `comments`
array with the evaluated comments.

## Workflow

1. Edit source files
2. Run `tricorder status --wait` — blocks until tricorder finishes recompiling
3. If errors are shown, fix them and repeat
4. `All good.` means the build is clean; test suites run automatically if configured
5. Run `tricorder test-results --wait --failed` to see any test failures

## Notes

- The daemon is per-project, scoped by the current working directory
- `tricorder status` auto-starts the daemon if it isn't running
- Do not run `cabal test` manually — the daemon manages test execution after each clean build
- Use `--json` only when you need to parse the full build state; the default text output is sufficient for most workflows
