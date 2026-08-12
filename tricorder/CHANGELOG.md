# Changelog

All notable changes to `tricorder` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Fixed

- `tricorder source` does not work without `cabal` in `PATH` (for `stack`
  projects, for example). Tricorder now fetches tarballs for source distributions
  manually with good old-fashioned HTTP instead of relying on `cabal fetch`.
  This means `tricorder source` works regardless whether `cabal` or `stack` is in
  `PATH`. (Still requires `ghc-pkg` to be in `PATH` though to resolve the module
  name to a package.)

## [0.2.0.0] - 2026-08-06

### Added

- The TUI can now restart the daemon — press `R` (the `restart_daemon` key
  event, rebindable like the others). It reconnects automatically once the
  fresh daemon is ready.
- Support for eval comments. See [Features of Tricorder - Eval Comments] for
  more information
- `tricorder eval-comments` subcommand.
- `tricorder log --print-path` prints the path to the current repo's Tricorder
  log file.

### Fixed

- No diagnostics are listed in single-package repos.
- Build loops on startup failure.

### Changed

- `tricorder source` now uses a package's sdist tarball from cabal's global
  cache instead of parsing Haddock-HTML, fetching them if necessary. This
  allows Tricorder to show sources for packages without documentation.

### Removed

- Observability and metrics stack.

## [0.1.1.0] - 2026-06-26

### Added

- Configurable `watch_exclusion_patterns` to exclude paths from the file
  watcher.
- The TUI now presents its different views as tabs.

### Fixed

- Terminate the whole cabal process group on shutdown, so children that trap
  `SIGINT` are no longer left running.
- Correct watch-directory scoping for bare package-name targets in a
  multi-package project.
- Building no longer fails for packages that use a custom prelude.
- Use the correct set of targets when constructing the build command.
- Surface location-less GHCi load failures (e.g. plugin errors) without
  reporting false positives.
- Clear stale diagnostics for failed executable and test `Main` modules.

## [0.1.0.1] - 2026-06-06

### Fixed

- Renamed the installed executable from `tricorder-exe` to `tricorder` so
  `cabal install tricorder` provides a binary matching the package name.

## [0.1.0.0] - 2026-06-05

### Added

- Initial release: daemon-based GHCi build monitor communicating over a Unix
  socket.
- Commands: `start`, `stop`, `status [--wait]`, `watch`.
- `status` outputs structured JSON with build phase, module count, duration,
  and messages; each message includes `severity`, `file`, `line`/`col`,
  `title` (first line), and `text` (full body).
- Auto-detects cabal/stack projects and builds the
  `cabal repl --enable-multi-repl` command.
- Parses `.cabal` files to resolve `hs-source-dirs` for targeted file watching.
- Configurable via `.tricorder.toml` (targets, debounce, log file, etc.).
- File watcher with debouncing; auto-restarts the GHCi session on crash
  (fixes ghcid's crash-on-file-removal bug).

[Features of Tricorder - Eval Comments]: ../docs/features-of-tricorder.md#eval-comments
