# Restructure build loop - Work Package

## High-level description

The architecture of the Tricorder daemon is suboptimal, and severely hampers
maintainability of the project due to intricate and implicit dependencies on
share mutable states that are exposed through the effect system. Interrupting
the builder mid-build is a delicate process that requires calling the correct
set of functions to ensure each process is actually interrupted, and return
early.

---

## Core objective

Simplify and reorganize the build process around a central "build loop" where
dependencies of each component in the build loop is handled by a core
orchestration module, decoupling the builder itself from testing and eval
comments.

---

## Deliverables

- This proposal, documenting the suggested approach and overall design of this
  orchestration module.
- The `Tricorder.Daemon.Core` module, the orchestration module itself.
- A large rewrite of `Tricorder.Builder`, drastically simplifying its API.

---

## Metrics for success

- All existing tests that are still relevant pass.
- Reduced usage of `State` effects that live across multiple components.
- The entire build loop is contained in one module, `Tricorder.Daemon.Core`,
  and is straightforward to read.
