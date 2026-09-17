# Changelog

All notable changes to `atelier-prelude` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Added

- Proper support for GHC 9.14.

## [0.4.0.0] - 2026-09-16

### Removed

- Support for GHC 9.14. A faulty CI setup incorrectly stated that we were
  building and testing successfully on GHC 9.14.

## [0.3.1.0] - 2026-09-15

### Added

- Support for GHC 9.14.

## [0.3.0.0] - 2026-09-10

### Changed

- Require `effectful >=2.7 && <2.8`.
- Require `effectful-core >=2.7 && <2.8`.
- Require `effectful-plugin >=2.2 && <2.3`.

## [0.2.0.0] - 2026-08-13

### Changed

- Relax `base` constraint to support GHC 9.6 up to GHC 9.12.

## [0.1.0.0] - 2026-06-04

### Added

- Initial release: a relude-based custom prelude adapted for Effectful
  conventions, extracted from the atelier toolkit.
- Lifted system, environment, handle, terminal and file operations
  (`Relude.Lifted.*` and `Relude.File`) and console output (`Relude.Print`)
  are intentionally not re-exported; the corresponding `atelier-core` effects
  (e.g. `Atelier.Effects.Env`, `Atelier.Effects.File`, `Atelier.Effects.Console`)
  should be used instead.
