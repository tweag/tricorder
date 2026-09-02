---
name: tricorder-mcp
description: Check GHCi build status, diagnostics, and test results for this Haskell project via the tricorder MCP server. Use when asked to check the build, see compiler errors/warnings, or run tricorder.
user-invocable: true
allowed-tools: Bash(tricorder *)
---

# Using the tricorder MCP Server

Use the `mcp__plugin_tricorder-mcp_tricorder__*` MCP tools for GHCi build
status, diagnostics, and test results in this project — don't run `tricorder`
as a Bash command; the MCP server already wraps it.

## Tools

- `start` — start the daemon (no-op if already running)
- `stop` / `restart` — stop/restart the daemon; pass `force: true` to skip waiting on pending queries
- `status` — current build status: diagnostics, errors, warnings. Pass `wait: true` to block until an in-progress build finishes, `verbose: true` for full GHC message bodies, or `expand: N` to expand a single diagnostic. Returns JSON.
- `test_results` — output from the latest test run. Pass `wait: true` to block until the build/test cycle finishes, or `failed: true` to show only failing suites.
- `source` — Haskell source for one or more installed modules (e.g. `Data.Map.Strict` or `Data.Map.Strict#insert`). Prefer this over downloading tarballs.
- `eval_comments` — eval comments and their evaluated results from the latest build. Pass `wait: true` to block until the build finishes. Returns JSON.
- `log_contents` / `log_path` — the daemon's log output, or the path to its log file.

All tools accept an optional `projectRoot` (defaults to the current working directory).

## Workflow

1. Edit source files.
2. Call `status` with `wait: true` — blocks until tricorder finishes recompiling.
3. If errors are shown, fix them and repeat.
4. A clean result means the build is clean; configured test suites run automatically.
5. Call `test_results` with `wait: true, failed: true` to see any test failures.

## Notes

- The daemon is per-project, scoped by the resolved project directory.
- `status` auto-starts the daemon if it isn't running.
- Do not run `cabal test` manually — the daemon manages test execution after each clean build.
- If these MCP tools are unavailable, disconnected, or misbehave, and the
  `tricorder` CLI is installed, fall back to running it directly via Bash
  (see the `tricorder` skill from the `tricorder` plugin, if installed).
