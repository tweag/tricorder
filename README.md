# Tricorder

Tricorder aims to empower users developing programs with Haskell and LLM
coding agents. It does so by providing operations to surface the right
information required at a given stage: documentation, build status,
diagnostics, etc.

> ℹ️ More information about how to use `tricorder` can be found in [this presentation](https://youtu.be/vDmyl0ZJRF8?t=4815)
> for the Haskell Foundation's "Haskell and AI Workshop".

Like similar tools (`ghcid`, `ghciwatch`), it builds the code continuously on
every change, presents diagnostics, and runs the tests afterwards. However,
Tricorder offers other advantages:

- **Designed for humans** - A `tricorder ui` interactive TUI mode that presents
  stats in real time for developers.
- **Designed for agents** - A `SKILL` is provided to inform agentic usage via
  the `tricorder` CLI.
- **Background builds** - Building in the background using a daemon allows
  different clients to query the build state simultaneously without triggering
  multiple rebuilds. For instance, we ship the `tricorder ui` TUI and the
  `tricorder status` CLI command that communicate witha single daemon via a
  socket.
- **Sane defaults** - Running `tricorder start` should Just Work™ for most
  cabal-based Haskell projects.
  - Daemon restarts automatically when cabal files change
  - If customization is needed it can be provided at different levels via a
    `.tricorder.yaml` or CLI args.
    - Optional config includes which cabal packages to watch, which exact
      command to use to enter a GHCi session, [customizable key
      bindings](#custom-key-bindings), etc.
- **Multi-package projects** - In a `cabal.project` workspace, Tricorder
  discovers every package's components automatically, building and running
  tests across all of them — no manual target configuration needed.
- **Project context** - Tools like `tricorder source Some.Module` will attempt
  to find and provide the source code for a given dependency from disk, which
  allows exploring library APIs more easily.
- **Machine-readable output** - Using `tricorder status --json` we can get
  build information in a format appropriate for programmatic usage.

For a deeper guide on the various features of Tricorder, see [Features of
Tricorder](./docs/features-of-tricorder.md).

## Usage

With the `tricorder` CLI in your path, start the Tricorder daemon either
explicitly with `tricorder start` or automatically by just running `tricorder
ui`, which will start the daemon if it's not already running and show you the
TUI.

For using Tricorder with Claude Code, see [Using with Claude Code](/docs/using-with-claude-code.md).

## Installation

Tricorder is supported on both Linux and macOS.

Tricorder is published on both on [Hackage][hackage-package] and on
[Stackage][stackage-package] from
[Stackage Nightly 2026-08-19][stackage-nightly-2026-08-19] and onwards, so you
may install it using either `cabal` or `stack`, whichever is your preference:

```bash
cabal install tricorder
# Or
stack install tricorder
```

Tricorder is also released as [pre-built binaries on GitHub][github-releases].

To install and use Tricorder in your NixOS configuration, see [Using with
Nix](/docs/using-with-nix.md).

### GHC 9.14 support

Currently, multiple of our dependencies do not support GHC 9.14, and as such we
are not able to officially support 9.14 just yet. But stay tuned, as we are
eager to utilize [the new multi-home features](https://www.youtube.com/watch?v=0tOciI7lMEE)!

## Configuring

See [Configuring Tricorder](/docs/configuring-tricorder.md)

## Development

```bash
nix develop
tricorder ui
```

## Libraries

This repository also contains [Atelier](atelier-core/README.md), a set of
Haskell libraries providing foundational infrastructure for effect-based
applications (to be extracted into their own repository).

## Project template

To scaffold a new Atelier-based service from the bundled `canvas` flake
template — an internal library plus a WAI/Warp executable with rel8/hasql
Postgres access, sqitch migrations, and a
[haskell.nix](https://input-output-hk.github.io/haskell.nix/) dev shell:

```bash
# Into a new directory:
nix flake new -t github:tweag/tricorder#canvas ./my-service

# …or into the current (empty) directory:
nix flake init -t github:tweag/tricorder#canvas
```

Then, from the generated project:

```bash
nix develop          # or `direnv allow` to load the dev shell automatically
nix run .#postgres   # start a local dev Postgres, then `sqitch deploy dev`
cabal run canvas     # start the server (GET /, /health, /metrics, /items)
```

`canvas` is a placeholder name — the generated `README.md` explains how to
rename it. See [`templates/canvas`](templates/canvas) for the full layout. The
template is exercised in CI against both the released Atelier packages and this
repo's in-development sources (`canvas-hackage` / `canvas-local` in
`nix/template-checks.nix`).

[hackage-package]: https://hackage.haskell.org/package/tricorder
[stackage-package]: https://www.stackage.org/nightly-2026-08-31/package/tricorder-0.2.1.0
[stackage-nightly-2026-08-19]: https://www.stackage.org/nightly-2026-08-19
[github-releases]: https://github.com/tweag/tricorder/releases
