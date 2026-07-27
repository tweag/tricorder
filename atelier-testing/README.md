# atelier-testing

Test utilities for database-backed tests using [tmp-postgres](https://github.com/jfischoff/tmp-postgres). Part of the **atelier** toolkit.

## Overview

`atelier-testing` spins up a throwaway PostgreSQL instance for integration tests, so suites that exercise [`atelier-db`](https://github.com/tweag/tricorder/tree/main/atelier-db) can run against a real database without external setup.

| Module | Purpose |
|---|---|
| `Atelier.Testing.Database` | Provision and tear down a temporary PostgreSQL database for tests |

## Part of atelier

- [`atelier-prelude`](https://github.com/tweag/tricorder/tree/main/atelier-prelude) — relude-based prelude with Effectful conventions
- [`atelier-core`](https://github.com/tweag/tricorder/tree/main/atelier-core) — foundational effects and utilities
- [`atelier-db`](https://github.com/tweag/tricorder/tree/main/atelier-db) — relational database effect (Hasql/Rel8)
- [`atelier-testing`](https://github.com/tweag/tricorder/tree/main/atelier-testing) — this package

## License

MIT — see [LICENSE](LICENSE).
