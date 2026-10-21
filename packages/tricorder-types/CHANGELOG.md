# Changelog

All notable changes to `tricorder-types` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Added

- Moved all argument parsing functionality from `tricorder` to
  `tricorder-types` for module locality.

### Changed

- `Tricorder.API.Daemon.Command.DaemonCommand` renamed to
  `Tricorder.API.Daemon.Command.Command`.

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
