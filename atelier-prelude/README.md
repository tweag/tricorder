# atelier-prelude

A custom prelude based on [relude](https://github.com/kowainik/relude), adapted for [Effectful](https://github.com/haskell-effectful/effectful) conventions. Part of the **atelier** toolkit.

## Usage

`atelier-prelude` exposes a module named `Prelude`. To make it the implicit prelude, hide `base`'s `Prelude` with a mixin — GHC's automatic `import Prelude` then resolves to this one, with no `NoImplicitPrelude` and no per-module imports.

In `package.yaml` (hpack):

```yaml
dependencies:
  - name: base
    mixin:
      - hiding (Prelude)
  - atelier-prelude
```

or in a `.cabal` file:

```cabal
build-depends: base, atelier-prelude
mixins:        base hiding (Prelude)
```

Add `-Wno-implicit-prelude` to your `ghc-options` to silence the implicit-prelude warning.

## What's different from relude

Lifted, `IO`-based operations from relude are intentionally **not** re-exported, so that effects are threaded explicitly through Effectful rather than performed in `IO`:

- `Relude.Lifted.*` (system, environment, handle, terminal, file operations)
- `Relude.File`
- `Relude.Print` (console output)

Use the corresponding `atelier-core` effects instead — e.g. `Atelier.Effects.Env`, `Atelier.Effects.File`, `Atelier.Effects.Console`.

## Part of atelier

- [`atelier-prelude`](https://github.com/tweag/tricorder/tree/main/atelier-prelude) — this package
- [`atelier-core`](https://github.com/tweag/tricorder/tree/main/atelier-core) — foundational effects and utilities
- [`atelier-db`](https://github.com/tweag/tricorder/tree/main/atelier-db) — relational database effect (Hasql/Rel8)
- [`atelier-testing`](https://github.com/tweag/tricorder/tree/main/atelier-testing) — database-backed test utilities
- [`atelier-monitoring`](https://github.com/tweag/tricorder/tree/main/atelier-monitoring) - observability and monitoring effects and utilities

## License

MIT — see [LICENSE](LICENSE).
