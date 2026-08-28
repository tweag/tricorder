# Changelog

All notable changes to `tricorder` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Added

- The daemon now shuts itself down after a period of inactivity, configurable
  with `idle_timeout_seconds` (defaults to 300 seconds; `0` disables it). Any
  client request resets the countdown, and a `tricorder ui` client's
  long-lived watch connection counts as continuous activity for as long as
  it's connected. See [Configuring Tricorder](/docs/configuring-tricorder.md)
  for more information.
- Use the `test_memory_limit` configuration value to specify the maximum memory
  a test suite is allowed to consume. This is enforced through GHC's `-M` RTS
  option.
- Hooks for running arbitrary shell scripts at certain points in time in the
  build process. See [Configuring Tricorder](/docs/configuring-tricorder.md)
  for more information.

### Fixed

- Unable to correctly parse `packages` lists in `cabal.project` files when the
  list was formatted as a single-line, comma-separated list.

## [0.2.1.0] - 2026-08-17

### Added

- Tricorder now respects all forms of `cabal.project` files, like
  `cabal.project.local` for example. See
  [Cabal's documentation on project description files](https://cabal.readthedocs.io/en/stable/cabal-project-description-file.html). ([#73](https://github.com/tweag/tricorder/issues/73))
- With `hpack` in `PATH`, Tricorder will now run `hpack` in the directory of
  any changed `package.yaml` file in the root of the project or any
  subdirectory. Control this behavior with the `generate_with_hpack`
  configuration.
- Tricorder will now restart the GHCi session when detecting changes to a
  project's `stack.yaml`.

## [0.2.0.1] - 2026-08-12

### Fixed

- `tricorder source` does not work without `cabal` in `PATH` (for `stack`
  projects, for example). Tricorder now fetches tarballs for source
  distributions manually with good old-fashioned HTTP instead of relying on
  `cabal fetch`. This means `tricorder source` works regardless whether `cabal`
  or `stack` is in `PATH`. (Still requires `ghc-pkg` to be in `PATH` though to
  resolve the module name to a package.)
- Incorrect repl command used for eval comments. This caused eval comments not
  to be able to use a module's top-level definitions in its expression.
- Auto-resolved targets are not compatible with `stack ghci` (and its alias
  `stack repl`). Targets are now automatically resolved with package name,
  `pkg:kind:name` for multi-package repos and just `name` for single-package
  repos, instead of just with the component name and kind `kind:name`. `stack
ghci` is not compatible with the form `kind:name` (but `cabal repl` is), but
  both of them are compatible with the fully qualified `pkg:kind:name` form. If
  you manually specify a `kind:name` target in your `stack` repo's
  `.tricorder.yaml` though, you are on your own!

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
