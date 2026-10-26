# Materialized dependency plans

The default development project and its shell tools can use dependency plans
stored in `nix/materialized/<system>/<compiler>/`. This avoids running Cabal's
solver to discover those dependencies when entering the shell. The initial
plans cover `x86_64-linux` with GHC 9.14.1. Other platforms and compiler versions
fall back to normal plan generation; static builds always generate their own
plans because their target differs.

From the repository root, regenerate the default project and all seven tool
plans for your current platform:

```sh
nix run .#update-materialization
```

Regenerate after changing package versions, dependencies, flags, the default
compiler, shell tool settings, or relevant flake inputs. The Hackage index date
is pinned as `index-state` in `nix/package/common.nix`; advance it deliberately
when updating dependencies. `cabal` remains managed by haskell.nix so it matches
the Cabal version used to build the project's dependency store.

Add newly generated files to Git before using the Git-backed flake:

```sh
git add nix/materialized
```

While preparing untracked changes, `nix run path:.#update-materialization` also
works. Do not format or edit generated files manually. The regeneration command
replaces each plan directory using haskell.nix's `generateMaterialized` helper.

Validate the current platform's plans with:

```sh
nix build --no-link .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).materialization
```

This check regenerates the plans and compares them with the stored copies. It
also runs as part of `nix flake check` in CI. Checking intentionally performs the
work that normal shell evaluation skips.

Materialization trades repository size and regeneration maintenance for less
evaluation work. It does not remove compiler evaluation dependencies, guarantee
that all Hackage/Stackage metadata downloads disappear, or reduce the shell's
runtime dependency closure.
