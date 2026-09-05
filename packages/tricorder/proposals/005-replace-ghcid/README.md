# Custom GHCi Session Manager — Completed

## Summary

This work replaced the `ghcid` library with a custom, internal GHCi session manager.
The public interface — the `GhciSession` effect and `LoadResult` type — is unchanged.
Only the interpreters that back them changed.

**Deliverables shipped:**

- `Tricorder.Internal.GhciProcess` — subprocess lifecycle, sentinel-marker sync protocol, shutdown
- `Tricorder.Internal.GhciParser` — pure parser for raw GHCi output, `LoadResult`, and utilities
- `Tricorder.Internal.GhcidBackend` — isolated wrapper around the old `ghcid`-library functions, kept for easy future deletion
- `runGhciSessionCustom` interpreter backed by the new modules
- `runGhciSessionFromEnv` — runtime backend selector via `TRICORDER_GHCI_BACKEND`
- Unit test suite for `GhciParser`

The `ghcid` library dependency has not yet been removed; `GhcidBackend` isolates all
references to it in one module so the removal is straightforward when ready.

---

## Module Map

| Module | Role |
|---|---|
| `Tricorder.Internal.GhciParser` | Pure parser: `GhciLoad`, `GhciSeverity`, `LoadResult`, `parseReload`, `parseShowModules`, `stripAnsi`, `extractTitle`, `toRelative` |
| `Tricorder.Internal.GhciProcess` | Process manager: `Config`, `GhciProcess`, `GhciProcessError`, `withGhciProcess`, `execGhci`, `collectResultCustom` |
| `Tricorder.Internal.GhcidBackend` | Old-backend wrapper: `collectResult`, `stopGhciSilently`, `toDiagnostics`, `parseProgress` |
| `Tricorder.Daemon.GhciSession` | Effect + all interpreters: `runGhciSessionIO`, `runGhciSessionCustom`, `runGhciSessionFromEnv`, `runGhciSessionScripted` |

---

## Background Documents

- [`research.md`](research.md) — how `ghcid` and `ghciwatch` manage GHCi subprocesses, and what tricorder needs
- [`design.md`](design.md) — design decisions made, alternatives rejected, the backend-selector mechanism
- [`spec.md`](spec.md) — module interfaces, types, and behaviour as implemented

---

## Selecting the Backend

Set `TRICORDER_GHCI_BACKEND=custom` to use the new implementation. The default is
`ghcid` (the old implementation). `Daemon.Main` uses `runGhciSessionFromEnv`
unconditionally; the selected backend is logged at startup.

---

## Classification

- **Nature:** Technical (refactor / dependency isolation)
- **Status:** Custom backend implemented and tested. Old backend isolated. `ghcid`
  dependency not yet removed from `tricorder.cabal` — `GhcidBackend` is ready for
  that step.
