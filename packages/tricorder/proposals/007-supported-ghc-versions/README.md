# Supported GHC Versions — Work Package

## High-level Description

Tricorder has no documented policy for which GHC versions it supports, builds, or tests. The version set has grown organically — versions were added when convenient and never formally removed. There is no stated rule a contributor can use to decide when to add a new version or when to drop an old one.

The rebase onto the `common.nix` branch introduced a canonical source for GHC version configuration (`nix/package/common.nix`), which both the Nix build and the cabal `tested-with` fields now read from. This proposal documents the policy, describes how the machinery works, and identifies the remaining gaps.

The policy is: **support every GHC version where `isEol` is `false` per [endoflife.date/ghc](https://endoflife.date/ghc)**.

As of 2026-06-19, the non-EOL versions are 9.6, 9.8, 9.10, 9.12, and 9.14. The current state:

| Version | Latest | In `common.nix` | In CI | Notes |
|---------|--------|-----------------|-------|-------|
| 9.14 | 9.14.1 | No | No | Non-EOL, LTS — excluded pending build fix |
| 9.12 | 9.12.4 | Yes (`9.12`) | Yes (`ghc9124`) | |
| 9.10 | 9.10.3 | Yes (`9.10.2`, default) | Yes (`ghc9102`) | |
| 9.8 | 9.8.4 | Yes (`9.8`) | Yes (`ghc984`) | |
| 9.6 | 9.6.7 | Yes (`9.6`) | No | **CI gap** |

**Deliverables:**
- This proposal, documenting the support policy and the build/test machinery
- `.github/actions/ghc-versions` composite action deriving the CI matrix from `common.nix`
- Both CI workflows updated to use the action (GHC 9.6 automatically included)
- GHC 9.14 tracked as a known gap; added to `common.nix` once the build failures are resolved

---

## Core Objectives

- Every non-EOL GHC version is built and tested on every CI run, on both supported platforms (x86_64-linux, aarch64-darwin)
- `nix/package/common.nix` is the single authoritative list of supported versions; CI picks up changes automatically
- A single, externally maintained criterion determines which versions are in scope
- Adding and dropping versions follows a documented, low-ceremony process

---

## Metrics for Success

- CI passes on all non-EOL GHC versions on both platforms
- A contributor can determine whether to include a GHC version by checking one URL
- `nix/package/common.nix` and the CI matrix are in sync

---

## Classification

- **New initiative or continuation of existing:** New initiative (builds on common.nix infrastructure)
- **Primary nature:** Non-technical (policy) with small technical components (CI updates)

---

## Milestones

### Milestone 1 — Policy + composite action

**Deliverables:**
- This proposal merged
- `.github/actions/ghc-versions` composite action implemented
- Both CI workflows updated to derive their matrix from `common.nix` via the action
- GHC 9.6 consequently included in CI (it is already in `common.nix`)

**Acceptance criteria:** CI passes on GHC 9.6 on both x86_64-linux and aarch64-darwin.

**Estimated duration:** 1 day (dominated by CI wait time)

### Milestone 2 — GHC 9.14 support restored

**Deliverables:**
- Build failures for GHC 9.14 investigated and fixed
- `9.14.1` (or current latest) added to `additional-ghc-versions` in `common.nix`
- GHC 9.14 added to the CI matrix

**Acceptance criteria:** CI passes on GHC 9.14 on both platforms.

**Estimated duration:** Unknown; depends on the nature of the build failures.

---

## Notes

GHC 9.6 and 9.8 are EOAS (End of Active Support) but not EOL — they still receive critical fixes and remain in scope until their `isEol` flag flips. At that point they can be removed without a deprecation period.

GHC 9.14 support was dropped in commit `728b85b4` due to build failures. It is non-EOL (LTS) and should be restored once those failures are addressed.

The `default-ghc-version` in `common.nix` (currently `9.10.2`) is the version used for `nix develop` and default outputs. It does not need to track the latest release and is updated separately from the support matrix.
