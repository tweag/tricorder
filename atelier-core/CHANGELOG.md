# Changelog

All notable changes to `atelier-core` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Added

- `Atelier.Effects.Env`: `lookupEnv` picks out a single environment variable.

### Changed

- Major version bump for the following dependencies' upper version bounds:
  - `aeson`
  - `http-api-data`
  - `time`

### Removed

- Move all metrics and observability tooling to `atelier-monitoring`:
  - `Atelier.Component`: moved to `atelier-monitoring`.
  - `Atelier.Effects.Conc.Traced`: moved to `atelier-monitoring`.
  - `Atelier.Effects.Monitoring.Metrics`: moved to `atelier-monitoring`.
  - `Atelier.Effects.Monitoring.Metrics.Server`: moved to `atelier-monitoring`.
  - `Atelier.Effects.Monitoring.Metrics.Registry`: moved to `atelier-monitoring`.
  - `Atelier.Effects.Cache.Singleflight`: removed tracing capability. Old version
    with tracing capability is available in `atelier-monitoring` as
    `Atelier.Effects.Cache.Singleflight.Traced`.
  - `Atelier.Effects.Publishing#runPubSub`: moved to `atelier-monitoring` in
    `Atelier.Effects.Publishing.Traced`.
  - `Atelier.Effects.Publshing#runPubSub_`: renamed to `runPubSub`.

## [0.3.0.0] - 2026-08-06

### Added

- `Atelier.Effects.Process`: `getExecutablePath` returns the absolute path of
  the currently running executable, for re-invoking the program as a
  subprocess.
- `Atelier.Effects.Publishing.Pub:` `map` and `mapM` allows mapping over
  published effects, producing a new `Pub` effect with the transformed values.

### Changed

- Moved `Pub` and `Sub` out of `Atelier.Effects.Publishing` to separate modules,
  `Atelier.Effects.Publishing.Pub` and `Atelier.Effects.Publishing.Sub`
  respectively.

## [0.2.0.0] - 2026-06-26

### Added

- `Atelier.Effects.File` now re-exports `IOMode (..)`.
- `Atelier.Effects.Process`: `withProcessGroup` runs a process in its own
  process group and guarantees the whole group is torn down when the body
  returns or throws; `terminateProcessGroup` aborts a running group from
  another thread (for children that trap `SIGINT`, where interrupting the
  group is not enough).
- New module `Atelier.Effects.Process.Internal`, exposing the `RunningProcess`
  constructor for tests that fabricate a handle. Production code should not
  import it.

### Changed

- **Breaking:** `Atelier.Effects.Process.RunningProcess` is now a distinct
  `newtype` wrapping `System.Process.Typed.Process` (previously a type
  synonym). `getStdin`/`getStdout`/`getStderr` operate on the new type.

### Removed

- **Breaking:** `Atelier.Effects.Process` no longer exports `setCreateGroup`,
  `startProcess`, or `stopProcess`. Process lifecycle is now managed through
  `withProcessGroup`.

## [0.1.0.0] - 2026-06-05

### Added

- Initial release: foundational Effectful-based effects and utilities,
  extracted from the atelier toolkit.
