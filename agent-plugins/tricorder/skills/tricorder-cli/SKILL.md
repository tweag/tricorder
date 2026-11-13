---
name: tricorder-cli
description: Full CLI reference for the tricorder daemon (build diagnostics, test results, source lookup, eval comments, logs). This is the fallback invoked by the `tricorder` skill when the tricorder-mcp MCP tools aren't available or aren't working. Invoke `tricorder` first; it decides whether this is needed.
user-invocable: true
allowed-tools: Bash(tricorder *)
---

# Using the tricorder CLI

tricorder is a daemon-based GHCi build monitor. The daemon is per-project,
scoped by the current working directory, and every query command starts it if
it isn't running. Output is human-readable text by default, or JSON with
`--json`.

Run `tricorder <command> --help` for exact flags. [CLI.md](./CLI.md) holds the
`--help` output of every command.

## Workflow

1. Edit source files.
2. Run `tricorder status`. It blocks until the daemon finishes the pending build.
3. Fix any errors and repeat.
4. On `All good.`, the daemon runs the configured test suites. Run `tricorder test suites --failed-only` to see failures.

Never run `cabal build` or `cabal test` yourself. The daemon builds after every edit and runs tests after each clean build.

## Commands

| Command | Use |
| --- | --- |
| `status` | Build diagnostics and test summary |
| `test suites` | Test suites, cases, failures, output |
| `source` | Haskell source of project or installed modules |
| `eval-comments` | Results of eval comments in watched sources |
| `daemon info\|start\|stop\|restart` | Manage the daemon |
| `log` | Daemon log |
| `ui` | Interactive auto-refreshing display, for humans |

### Flags shared by the query commands

`status`, `test suites` and `eval-comments` accept:

- `-j, --json` for machine-readable output.
- `-c, --use-current` to skip waiting for the pending build and read the current, possibly incomplete, state.
- `--prevent-daemon` to fail instead of starting the daemon when it isn't running.

## status

One line per diagnostic with a 1-based index, then a summary:

```
[1] E src/Foo/Bar.hs:42 `something` not in scope
[2] W src/Foo/Bar.hs:10 redundant import
2 error(s), 1 warning(s) (71 modules, 1.2s)
```

Format: `[N] <E|W> <file>:<line> <title>`. A clean build prints:

```
All good. (71 modules, 17.3s)
```

Test suite results follow the summary when suites are configured:

```
All good. (71 modules, 17.3s)
test:my-test  passed
test:other-test  failed
```

- `-v, --verbose` prints the full GHC message under each diagnostic, and full test suite error messages.
- `--expand N` prints only diagnostic #N in full. Use it to read one error without the rest.

Exit code is 1 when any error is present or any test suite fails. Warnings alone give 0.

`--json` returns the full build state:

```json
{
  "buildId": 3,
  "phase": {
    "tag": "Finished",
    "contents": {
      "completedAt": "2026-03-30T12:00:00Z",
      "durationMs": 420,
      "moduleCount": 42,
      "testSuites": [...]
    }
  }
}
```

Prefer the text output. Reach for `--json` only when parsing the whole state.

## test suites

`tricorder test suites [TEST-TARGET...]` prints a YAML list, one entry per suite:

```yaml
- name: tricorder:test:tricorder-test
  status: failed
  passed_cases: 479
  total_cases: 480
  duration_ms: 250
```

- Name one or more `TEST-TARGET`s to show only those suites.
- `-f, --failed-only` shows only failed suites and, within them, only failed cases. When nothing failed it prints `no failed test suites`.
- `--fields` picks the fields. Available: `name`, `status`, `error`, `passed_cases`, `total_cases`, `duration_ms`, `output`, `cases(description, outcome, failure)`. Nest with parentheses.
- `--help-json` prints the JSON schema of the `--json` output.

To read why a case failed:

```
tricorder test suites --failed-only --fields 'name,cases(description,failure)'
```

Exit code is 1 when any shown suite failed or errored.

## source

`tricorder source Module[#function]` prints the Haskell source of a project or installed module, or of one function in it. Use it to read library code instead of hunting through the Nix store or `~/.cabal`.

- When the symbol isn't defined in the queried module, tricorder follows re-exports. `--max-depth N` (default 5) caps the hops, `--max-modules N` (default 24) caps the modules read.

## eval-comments

The daemon evaluates eval comments in the watched source files. Use them for quick type checks and experiments.

```
./src/Source/Module.hs (line 123)
Expression:
:t someFunc
Output:
someFunc :: Int -> Int
```

With `--json`:

```json
{
  "state": "done",
  "comments": [
    {
      "expression": ":t someFunc",
      "file": "./src/Source/Module.hs",
      "line": 123,
      "state": { "output": "someFunc :: Int -> Int\n\n", "state": "completed" }
    }
  ]
}
```

The top-level `state` is `done` once the build finishes. Only then does `comments` appear. Before that, `state` names the build stage the daemon is in.

## daemon and log

- `tricorder daemon info` shows daemon information (`--json` available).
- `tricorder daemon start` is a no-op when the daemon already runs.
- `tricorder daemon restart` and `stop` wait for clients with pending requests. `--ignore-pending-queries` skips the wait.
- `tricorder log` prints the daemon log. `--print-path` prints the log file path instead, for grepping or tailing.
