# Changelog

All notable changes to `tricorder-types` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Added

- `--help-json` flag for `tricorder test suites`, showing the JSON Schema of
  the output of `tricorder test suites --json`.
- `autodocodec` codecs (`HasCodec` instances) for `SuiteView`, `CaseView`,
  `Status` and `Outcome` in `Tricorder.API.Test.SuiteView`. Their `ToJSON`
  instances are derived from these.
- `Tricorder.API.FieldMask.Schema.fromCodec`, deriving the fields of a field
  mask `Schema` from a codec. `Tricorder.API.Test.SuiteView.Schema.schema` is
  derived from the codec of `SuiteView`.
- `Tricorder.API.FieldMask.Projection.codec`, encoding projections with their
  fields in selection order, and `Tricorder.API.FieldMask.Projection.optionalKeys`,
  for the JSON Schema of projections.
- `Tricorder.API.Response`, the JSON envelope (`Response`, `MessageWithLoc`)
  of command output and its codec, moved from `tricorder`.
- `Tricorder.API.Test.SuitesResponse`, the payload of
  `tricorder test suites --json` and its codec, moved from `tricorder`.

### Removed

- `ToJSON` instance of `Tricorder.API.FieldMask.Projection.Projection`, in
  favour of `Tricorder.API.FieldMask.Projection.codec`.

## [1.0.0.0] - 2026-10-29

### Changed

- `Tricorder.API.WaitMode`: renamed to `Tricorder.API.IfBuildIsPending`.
- `Tricorder.API.IfBuildIsPending`: wait for build to finish by default.
- `Tricorder.API.IfDaemonIsStopped`: start daemon by default.
- `Tricorder.API.Force`: renamed to `Tricorder.API.IfTherearePendingQueries`.

### Removed

- `test-results` subcommand.
- `start` subcommand.
- `stop` subcommand.
- `restart` subcommand.

## [0.6.0.0] - 2026-10-23

### Added

- Moved all argument parsing functionality from `tricorder` to
  `tricorder-types` for module locality.

### Changed

- `Tricorder.API.Daemon.Command.DaemonCommand` renamed to
  `Tricorder.API.Daemon.Command.Command`.
- `Tricorder.API` moved to `Tricorder.API.Command`.
- `Tricorder.API.Args` moved to `Tricorder.API.Command.Args`.
- `Tricorder.API.Command.commandToArgs` renamed to `Tricorder.API.Command.toArgs`.

## [0.5.0.0] - 2026-10-20

### Added

- `Command`'s `Test` constructor for the `tricorder test` subcommand, with
  `Tricorder.CLI.Command.FieldMask` for selecting fields of the response.
  Non-breaking.
- Move all `FieldMask` modules and functionality to one place here in
  `tricorder-types` instead of having them spread out between `tricorder` and
  `tricorder-types`.

### Changed

- **Breaking:** `Command`'s `Source` constructor now takes a `SourceOptions`
  record (`queries`, `maxDepth`, `maxModules`) instead of `[SourceQuery]`.
  `commandToArgs` renders the limits as `--max-depth` / `--max-modules`.

## [0.4.2.0] - 2026-10-02

### Added

- `Daemon.Info` command.

## [0.4.1.0] - 2026-09-17

### Added

- Proper support for GHC 9.14.

## [0.4.0.0] - 2026-09-16

### Removed

- Support for GHC 9.14. A faulty CI setup incorrectly stated that we were
  building and testing successfully on GHC 9.14.

## [0.3.1.0] - 2026-09-15

### Added

- Support GHC 9.14.

## [0.3.0.0] - 2026-09-11

### Removed

- Dependency on `effectful-core` and `effectful-plugin`.

## [0.2.0.0] - 2026-09-10

### Changed

- Require `effectful-core >=2.7 && <2.8`.
- Require `effectful-plugin >=2.2 && <2.3`.

## [0.1.0.0] - 2026-08-24

### Added

- Initial release.
