# Changelog

All notable changes to `atelier-core` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Added

- `Atelier.Effects.FSNotify`: `System.FSNotify` lifted to `Eff`.

### Changed

- `Atelier.Effects.Arguments`: converted to a static effect.
- `Atelier.Effects.Arguments.runArgumentsIO` renamed to
  `Atelier.Effects.Arguments.runIO`.
- `Atelier.Types.Base64` moved to `Atelier.Types.JSON.Base64`.
- `Atelier.Types.WithDefaults` moved to `Atelier.Types.JSON.WithDefaults`.
- `Atelier.Effects.Cache`: renamed members to make more suited for qualified
  use.
- `Atelier.Effects.Chan`: renamed members to make more suited for qualified
  use.
- `Atelier.Effects.Clock`: renamed members to make more suited for qualified
  use.
- `Atelier.Effects.Conc`: renamed members to make more suited for qualified
  use.
- `Atelier.Effects.Console`: renamed members to make more suited for qualified
  use.
- `Atelier.Effects.Debounce`: renamed members to make more suited for qualified
  use.
- `Atelier.Effects.Delay`: renamed members to make more suited for qualified
  use.
- `Atelier.Effects.Env`: renamed members to make more suited for qualified use.
- `Atelier.Effects.Exit`: renamed members to make more suited for qualified
  use.
- `Atelier.Effects.File`: renamed members to make more suited for qualified
  use.
- `Atelier.Effects.FileSystem`: renamed members to make more suited for
  qualified use.
- `Atelier.Effects.FileWatcher`: renamed members to make more suited for
  qualified use.

### Removed

- Deprecated functions in `Atelier.Effects.Input`.

## [0.8.1.0] - 2026-10-23

### Added

- `Atelier.Effects.Console.runConsoleOut` and `Atelier.Effects.Console.Output`:
  to run `Console` effects against specific well-known handlers, like `stdout`
  and `stderr`.

## [0.8.0.0] - 2026-10-20

### Added

- `Atelier.Types.JSON.StringLiteral`: helper `newtype` for parsing and encoding
  values as exact string literals, regardless of their `Show` and `Read`
  instances.
- `Atelier.Types.JSON.ReadShow`: a copy of `Atelier.Types.JsonReadShow`, but
  with a better name.
- `Atelier.Types.JSON.QuietSnake`: a copy of `Atelier.Types.QuietSnake`, but
  with a better name.
- `Atelier.Effects.Input.withEff`: a copy of
  `Atelier.Effects.Input.runInputEff`, but with a better name.
- `Atelier.Effects.Input.withConst`: a copy of
  `Atelier.Effects.Input.runInputConst`, but with a better name.
- `Atelier.Effects.PubSub`: a copy of
  `Atelier.Effects.Publishing`, but with a better name.
- `Atelier.Effects.PubSub.Pub`: a copy of
  `Atelier.Effects.Publishing.Pub`, but with a better name.
- `Atelier.Effects.PubSub.Sub`: a copy of
  `Atelier.Effects.Publishing.Sub`, but with a better name.
- `Atelier.Effects.Reader.project`: a simple way to expose parts of another
  `Reader a` as another `Reader` effect.
- `Atelier.Effects.Input.map`: a function to transform an existing effect.
- `Atelier.Effects.Log.Config`: gets a `ToJSON` instance.
- `Atelier.Effects.Log.Severity`: gets a `ToJSON` instance.

### Changed

- `Atelier.Effects.Log.Config`: its `FromJSON` instance now fails gracefully
  using the `Default` instance.

### Deprecated

- `Atelier.Types.JsonReadShow`: superseded by `Atelier.Types.JSON.ReadShow`.
- `Atelier.Types.QuietSnake`: superseded by `Atelier.Types.JSON.QuietSnake`.
- `Atelier.Effects.Input.runInputEff`: superseded by `Atelier.Effects.Input.withEff`.
- `Atelier.Effects.Input.runInputConst`: superseded by `Atelier.Effects.Input.withConst`.
- `Atelier.Effects.Publishing`: superseded by `Atelier.Effects.PubSub`.
- `Atelier.Effects.Publishing.runPubSub`: superseded by `Atelier.Effects.PubSub.run`.
- `Atelier.Effects.Publishing.Pub`: superseded by `Atelier.Effects.PubSub.Pub`.
- `Atelier.Effects.Publishing.Sub`: superseded by `Atelier.Effects.PubSub.Sub`.

## [0.7.3.0] - 2026-10-02

### Added

- `Atelier.Effects.FileSystem.getModificationTime`: Lifted `System.Directory.getModificationTime`.

## [0.7.2.0] - 2026-09-21

### Added

- `Atelier.Signal`: For properly handling termination of an application.

## [0.7.1.0] - 2026-09-17

### Added

- Proper support for GHC 9.14.

## [0.7.0.0] - 2026-09-16

### Removed

- Support for GHC 9.14. A faulty CI setup incorrectly stated that we were
  building and testing successfully on GHC 9.14.

## [0.6.1.0] - 2026-09-15

### Added

- `Atelier.Effects.FileSystem.Glob`: lifted functions from the `Glob` library.
- Support for GHC 9.14.

## [0.6.0.0] - 2026-09-10

### Changed

- Require `effectful >=2.7 && <2.8`.
- Require `effectful-core >=2.7 && <2.8`.
- Require `effectful-plugin >=2.2 && <2.3`.

## [0.5.0.0] - 2026-09-09

### Changed

- `Atelier.Time`: Remove orphan `FromJSON` and `ToJSON` instances, and instead
  introduce `AsRawUnit` and `AsJsonMicrosecond` `newtype`s for `FromJSON` and
  `ToJSON` instance deriving. This fixes the issue where the time units'
  `FromJSON` and `ToJSON` instances did not match, meaning
  `decode (encode (10 :: Hour)) == Nothing` held true. Now you have to be more
  explicit about how the units will be represented in JSON.

## [0.4.0.1] - 2026-08-14

### Removed

- Dependency on `hs-opentemeletry-api` for the test suite.

## [0.4.0.0] - 2026-08-14

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
