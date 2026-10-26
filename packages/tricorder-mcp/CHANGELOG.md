# Changelog

All notable changes to `tricorder-mcp` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Changed

- Uses the new flags for Tricorder's `status`, `daemon stop` and
  `daemon restart` commands.

## [0.2.0.0] - 2026-10-23

### Changed

- The `status` tool now shows only the first line of a test suite's error
  message unless `verbose` is set.
  ([#585](https://github.com/tweag/tricorder/issues/585))
- The `test_results` tool now uses the new, more granular
  `tricorder test suites` command.

## [0.1.3.1] - 2026-10-20

### Fixed

- Pre-built binaries on GitHub were built against paths in `/nix/store`, and
  were not portable to systems that did not have Nix installed. The binaries are
  now correctly linked to be used on non-Nix machines, and NixOS machines with
  `nix-ld` enabled.

## [0.1.3.0] - 2026-09-17

### Added

- Proper support for GHC 9.14.

## [0.1.2.2] - 2026-09-16

### Changed

- Bumped `atelier-core`, `atelier-prelude` and `tricorder-types`.

## [0.1.2.1] - 2026-09-11

### Changed

- Require `tricorder-types ^>=0.3`.

## [0.1.2.0] - 2026-09-10

### Changed

- Require `effectful-core >=2.7 && <2.8`.
- Require `effectful-plugin >=2.2 && <2.3`.

### Added

- Reintroduce project root argument, but as an optional argument, defaulting to
  using the current working directory. This allows the agent to control
  multiple Tricorder sessions at the same time.

## [0.1.1.0] - 2026-09-01

### Changed

- `tricorder-mcp` no longer requires the agent to pass the directory of the
  project in question, and will instead infer it from the current working
  directory or use the directory passed from the agent harness.
- Added more accurate and detailed descriptions for each tool.

## [0.1.0.0] - 2026-08-19

### Added

- Initial release.
