# Changelog

All notable changes to `atelier-db` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Changed

- Major version bump for the following dependencies' upper version bounds:
  - `aeson`
  - `atelier-core`
  - `hasql-pool`
  - `time`

## [0.2.0.0] - 2026-08-13

### Changed

- Relax `base` constraint to support GHC 9.6 up to GHC 9.12.

## [0.1.1.0] - 2026-06-29

### Added

- `DBConfig` derives `FromJSON` (via `QuietSnake`, mapping fields to
  `quiet_snake_case` keys), so connection settings can be decoded directly
  from configuration files.

## [0.1.0.0] - 2026-06-04

### Added

- Initial release: a relational database effect (Hasql/Rel8) for the atelier
  toolkit.
