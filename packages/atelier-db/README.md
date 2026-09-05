# atelier-db

Relational database access via [Hasql](https://github.com/nikita-volkov/hasql) and [Rel8](https://github.com/circuithub/rel8), exposed as an [Effectful](https://github.com/haskell-effectful/effectful) effect. Part of the **atelier** toolkit.

## Overview

`atelier-db` exposes database access as a first-class effect so queries can be
interpreted, mocked, and composed alongside the rest of your application's
effects.

## Part of atelier

- [`atelier-prelude`](https://github.com/tweag/tricorder/tree/main/atelier-prelude) — relude-based prelude with Effectful conventions
- [`atelier-core`](https://github.com/tweag/tricorder/tree/main/atelier-core) — foundational effects and utilities
- [`atelier-db`](https://github.com/tweag/tricorder/tree/main/atelier-db) — this package
- [`atelier-testing`](https://github.com/tweag/tricorder/tree/main/atelier-testing) — database-backed test utilities
- [`atelier-monitoring`](https://github.com/tweag/tricorder/tree/main/atelier-monitoring) - observability and monitoring effects and utilities

## License

MIT — see [LICENSE](LICENSE).
