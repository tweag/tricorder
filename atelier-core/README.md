# atelier-core

Foundational effects and utilities for effect-based applications, built on [Effectful](https://github.com/haskell-effectful/effectful). Part of the **atelier** toolkit.

## Overview

`atelier-core` provides a set of composable Effectful effects and supporting types for building structured, observable applications.

| Module | Purpose |
|---|---|
| `Atelier.Component` | Structured component lifecycle (`setup → listeners → start`) |
| `Atelier.Config` | Configuration with environment variable overrides |
| `Atelier.Effects.Log` | Structured logging with hierarchical namespaces |
| `Atelier.Effects.Conc` | Thread management via [Ki](https://github.com/awkward-squad/ki) (structured concurrency) |
| `Atelier.Effects.Cache` | Caching with singleflight deduplication |
| `Atelier.Effects.Publishing` | Event publishing with context propagation |
| `Atelier.Effects.Monitoring.Tracing` | OpenTelemetry tracing |
| `Atelier.Effects.Monitoring.Metrics` | Prometheus metrics |
| `Atelier.Effects.FileWatcher` | Filesystem change notifications |
| `Atelier.Effects.Process` | External process management |

It also wraps a number of `IO`-based primitives (environment, clock, file system, console, POSIX) as effects so they can be interpreted and tested explicitly: `Atelier.Effects.Env`, `Atelier.Effects.Clock`, `Atelier.Effects.FileSystem`, `Atelier.Effects.Console`, `Atelier.Effects.Posix.*`, and more.

## Part of atelier

- [`atelier-prelude`](https://github.com/tweag/tricorder/tree/main/atelier-prelude) — relude-based prelude with Effectful conventions
- [`atelier-core`](https://github.com/tweag/tricorder/tree/main/atelier-core) — this package
- [`atelier-db`](https://github.com/tweag/tricorder/tree/main/atelier-db) — relational database effect (Hasql/Rel8)
- [`atelier-testing`](https://github.com/tweag/tricorder/tree/main/atelier-testing) — database-backed test utilities

## License

MIT — see [LICENSE](LICENSE).
