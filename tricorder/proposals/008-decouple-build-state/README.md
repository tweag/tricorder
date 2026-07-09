# Decouple Build State into Cycle and Registers — Work Package

## High-level Description

Tricorder's `BuildState` packs lifecycle status and every producer's output — the
build result, test results, and (soon) eval-comment results — into a single
`BuildPhase` sum type behind one `TVar`. Because the outputs live *inside* the
lifecycle sum, any post-build task must carefully poke a field of that shared blob
without disturbing the phase. That coupling is the source of the `PostBuildStore`
effect (PR #263 / #265), the non-clobber discipline in every writer, and the
`Restarting`-clobber race.

This work separates the two things the blob conflates: a **cycle state machine**
(mutable, sequenced, single-writer) and a set of **producer output registers**
(single-writer-per-producer), so each producer writes only its own field. The
cycle's transitions are modelled as an event + `step` reducer, and outputs are held
in a `buildId`-keyed accumulator so builds stay coherent and separable.

**Deliverables:**
- A `BuildState` with an independent `cycle` phase and per-producer outputs held in
  a bounded, `buildId`-keyed accumulator (`build`, `tests`, later `evals`).
- A `CycleEvent` + `step` reducer owning cycle / `buildId` / build transitions,
  with `Restarting`-clobber resistance expressed as reducer clauses.
- Removal of the `PostBuildStore` effect and its interpreters.
- Preserved wire / CLI / TUI behaviour (`status`, `status --wait`, `stateLabel`).

---

## Core Objectives

- Post-build tasks cannot touch the cycle phase — structural, not by discipline.
- The `Restarting`-clobber race is impossible by construction.
- A straggling result for an older build cannot corrupt the current build.
- Adding a new post-build producer (eval comments) needs no change to cycle
  transition logic.
- Derived views (`stateLabel`, `isSettled` / `status --wait`) are pure folds over
  independent fields.

---

## Metrics for Success

- `PostBuildStore` and its interpreters are deleted; no `other -> other` clobber
  guards remain in the build/test writers.
- The existing Builder / TestRunner suites pass, plus new property tests over
  `step` (including clobber-resistance).
- `status`, `status --wait`, and the TUI show behaviour identical to `main` across:
  a clean build, an error build, a test run, and a `.cabal` restart.

---

## Classification

- **New initiative or continuation of existing:** New initiative; supersedes the
  approach in PR #263 / #265.
- **Primary nature:** Technical.

---

## Milestones

### Milestone 1 — State model + reducer

**Deliverables:**
- `CyclePhase`, `BuildOutput`, `TestOutput`, `BuildRecord`, and the reshaped
  `BuildState`.
- Pure `CycleEvent` + `step` reducer with property tests.

**Acceptance criteria:** `step` is total, clobber-resistant, and covered by tests;
no `TVar`/effect needed to exercise it.

### Milestone 2 — Rewire and delete `PostBuildStore`

**Deliverables:**
- `BuildStore` exposes `emit` / `setTests` / reads; raw `setPhase` / `modifyPhase`
  writers migrated.
- `afterLoad`, `runTestsForTargets`, `reportTestProgress` rewired onto the new API.
- `PostBuildStore` module removed.

**Acceptance criteria:** build green; existing suites pass; behaviour parity with
`main` on the four scenarios above.

### Milestone 3 — Accumulator + coherence

**Deliverables:**
- `buildId`-keyed accumulator with bounded eviction (K) and selection helpers.
- `stateLabel` / `isSettled` / `WaitForNext` defined against `history[current]`.

**Acceptance criteria:** cross-cycle retention works (last build visible while the
next runs); stragglers file under the correct build; wire payload bounded by K.

---

## Notes

- Supersedes #265 (separate test results from `BuildResult`) and consumes its
  data-model split.
- Feeds `feat/eval-comments` (#264) as the second producer — the eval runner
  becomes another register, no cycle changes.
- Wire-format change to `BuildState`; all clients (CLI, TUI, external) are in-repo.
- **Open decision (see `design.md`):** `buildId` granularity — dissolved if the
  accumulator is adopted; otherwise a per-session-vs-per-build call.
- `spec.md` holds the locked contracts (reducer, `BuildStore` API, wire format,
  straggler invariant), derived from an end-to-end implementation spike that ported
  the full library + test suite green (`354` + `218` tests).
