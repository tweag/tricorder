# Design: Restructure build loop

## Status

Implemented. See `README.md` for the work package.

---

## Problem

Tricorder is at this time poorly structured.

- The `Atelier.Component` framework is a poor fit for Tricorder since the
  components end up depending on each other too tightly, which
  `Atelier.Component`s are not fit for.
- Restarting the build loop is a very explicit process, requiring multiple
  safeguards to ensure the `Builder` is in the correct state after a restart.
- `Builder` is responsible for building as well as tests and eval comments. Its
  responsibilities exceed its name.
- Files watched by the `Watcher` are interesting only to `Builder`, so their
  interactions could be simplified.
- The `Observabiltiy` component and all observability code in the project,
  carries a lot of noise and weight, for little benefit.

---

## Approach

There are multiple steps that can be taken to resolving these issues:

- Instead of having `Builder` be responsible for _everything_, have a `Core`
  that calls to `Builder`, `EvalCommentsRunner` and `TestRunner`.

  Make this `Core` responsible for orchestrating `Builder`,
  `EvalCommentsRunner` and `TestRunner`, and the dependencies between each of
  these components and their outputs.

- Integrate `Watcher` into `Core` more properly.
- Remove `Observability` and the entire observability stack from Tricorder.

---

## Alternatives

The most obvious alternative is just to leave everything as they are, and
continue working with the current architecture. Given that we currently have
problems debugging and resolving some issues relating to cancelling the build
loop, this is not a particularly enticing alternative.

---

## Trade offs

A major refactor like this might introduce new bugs, or accidentally change the
characteristics of the problem in subtle ways that break the Package Version
Policy.
