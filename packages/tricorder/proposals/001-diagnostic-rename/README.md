# Rename `Message` to `Diagnostic` — Work Package

## High-level Description

The type representing a single compiler diagnostic is currently named `Message`, which
is generic to the point of being misleading — a message could be anything. `Diagnostic`
is the established term in the compiler tooling ecosystem (GHC, LSP, editors) and more
accurately describes what the type holds. Renaming it aligns tricorder's vocabulary with
the wider tooling landscape and makes the codebase easier to navigate for new
contributors.

The rename touches the wire protocol: the `messages` field in `BuildResult` becomes
`diagnostics`. This is a breaking change to the JSON API.

**Deliverables:**
- `Message` renamed to `Diagnostic` throughout the codebase
- `messages` field in `BuildResult` renamed to `diagnostics`
- All internal references, tests, and documentation updated

---

## Core Objectives

- **Align terminology with the ecosystem** — `Diagnostic` is the term used by GHC,
  LSP, and most editor integrations; using it in tricorder reduces cognitive friction.
- **Improve codebase clarity** — the rename makes it immediately obvious what the type
  represents without needing to read its definition.

---

## Metrics for Success

- No occurrence of the old name `Message` (in the diagnostic sense) remains in the
  codebase.
- The JSON protocol field is `diagnostics` in all responses.
- All tests pass.

---

## Classification

- **New initiative or continuation of existing:** New initiative
- **Primary nature:** Technical (refactor)

---

## Milestones

### Milestone 1 — Rename

**Deliverables:**
- `Tricorder.BuildState.Message` → `Tricorder.BuildState.Diagnostic`
- `BuildResult.messages :: [Message]` → `BuildResult.diagnostics :: [Diagnostic]`
- `LoadResult.messages` → `LoadResult.diagnostics`
- All effects, interpreters, components, render, and test modules updated
- JSON golden tests (if any) updated to reflect the new field name

**Acceptance criteria:**
The codebase compiles with no references to `Message` in the diagnostic sense. The
wire protocol emits `diagnostics` where it previously emitted `messages`.

**Estimated duration:** half a day

---

## Notes

The `messages` → `diagnostics` field rename is a breaking change. Since tricorder has no
stable public API commitment yet, this should be done before any such commitment is
made. If clients exist that depend on the current field name, coordinate the rename
with a version bump.
