# Changelog

All notable changes to `atelier-prelude` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

## [0.1.0.0] - 2026-06-04

### Added

- Initial release: a relude-based custom prelude adapted for Effectful
  conventions, extracted from the atelier toolkit.
- Lifted system, environment, handle, terminal and file operations
  (`Relude.Lifted.*` and `Relude.File`) and console output (`Relude.Print`)
  are intentionally not re-exported; the corresponding `atelier-core` effects
  (e.g. `Atelier.Effects.Env`, `Atelier.Effects.File`, `Atelier.Effects.Console`)
  should be used instead.
