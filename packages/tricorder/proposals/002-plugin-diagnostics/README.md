# Plugin-Based Structured Diagnostics — Work Package

## High-level Description

GHC diagnostics carry more information than tricorder currently surfaces. Error codes,
structured hints, and related spans ("see definition at…") are present in the compiler
but not available to clients — they appear as prose in the message text, if at all.
This limits what editors and tooling built on tricorder can do with build output.

This work package extends tricorder to expose that richer diagnostic data by introducing
`tricorder-plugin`, an optional GHC compiler plugin users add to their project. Projects
that do not install the plugin continue to work as before with no user-visible change.

**Deliverables:**
- `tricorder-plugin` library: GHC compiler plugin with Logger wrapping and socket
  forwarding
- Updated `GhciSession` interpreter: plugin socket mode with ghcid fallback
- Extended `Message` type: `errorCode`, `hints`, `relatedSpans` fields
- User documentation: how to add `tricorder-plugin` to a cabal file

---

## Core Objectives

- **Eliminate fragile output parsing** — diagnostics arrive as native GHC values
  rather than parsed from human-readable text.
- **Expose richer diagnostic data** — error codes, structured hints, and related spans
  become available to clients without any change to the daemon binary distribution.
- **Maintain zero-setup fallback** — the daemon works out of the box for projects that
  have not installed the plugin, with a clear log message guiding users toward richer
  output.
- **No GHC version coupling in the daemon** — the daemon binary does not link against
  the `ghc` library; version negotiation is handled by cabal when it compiles the
  plugin.

---

## Metrics for Success

- A project with `tricorder-plugin` installed emits `Message` values with non-empty
  `errorCode` fields for GHC errors that carry codes.
- A project without `tricorder-plugin` continues to work as before, with the daemon
  logging which mode it is in.
- The `ghcid` dependency can be listed as optional / fallback-only in the cabal file.

---

## Classification

- **New initiative or continuation of existing:** New initiative
- **Primary nature:** Technical

---

## Milestones

### Milestone 1 — tricorder-plugin Library

**Deliverables:**
- `Tricorder.Plugin` module with `plugin :: Plugin` entry point
- `driverPlugin` hook: reads `TRICORDER_PLUGIN_SOCKET` from env; no-op if absent
- Logger wrapping via `pushLogHook` / `putLogHook` (GHC 9.8+, no CPP)
- `DiagnosticEvent` JSON type covering severity, location, message, errorCode,
  hints, relatedSpans
- Plugin connects to daemon socket and writes newline-delimited JSON

**Acceptance criteria:**
Running `cabal repl` on a project with `-fplugin=Tricorder.Plugin` and
`TRICORDER_PLUGIN_SOCKET` set produces `DiagnosticEvent` JSON on the socket for each GHC
diagnostic. Running without the env var produces no output and no errors.

**Estimated duration:** 1 week

---

### Milestone 2 — Daemon Plugin Mode

**Deliverables:**
- Plugin socket server in the `GhciSession` interpreter
- Startup: daemon opens socket, sets `TRICORDER_PLUGIN_SOCKET`, spawns GHCi, waits up
  to 5 seconds for plugin connection
- Plugin mode: accumulate `DiagnosticEvent`s per reload cycle; detect completion via
  `"Ok/Failed, N modules loaded."` stdout line
- Fallback mode: delegate to existing ghcid path unchanged; log which mode is active
- Extended `Message` type with `errorCode :: Maybe Text`, `hints :: [Text]`,
  `relatedSpans :: [RelatedSpan]`

**Acceptance criteria:**
- With plugin installed: `tricorder status` returns messages with `errorCode` populated
  for errors that carry GHC error codes.
- Without plugin installed: `tricorder status` returns messages as before; daemon log
  shows `"tricorder-plugin not detected; falling back to basic diagnostics"`.

**Estimated duration:** 1–2 weeks

---

### Milestone 3 — End-to-End Validation and Documentation

**Deliverables:**
- Integration test against a real cabal project covering both plugin mode and fallback
- Verified: error codes, hints, and related spans round-trip correctly through the
  JSON protocol to clients
- User-facing documentation: how to add `tricorder-plugin`, what the new fields contain,
  link to `errors.haskell.org`

**Acceptance criteria:**
Integration test passes in CI. Documentation covers the setup step in under five
minutes of reading.

**Estimated duration:** 1 week

---

## Supporting Material

- Design: `design.md`
- Spec: `spec.md`
- Research: `research.md`
