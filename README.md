# Tricorder

`tricorder` aims to empower users developing programs with Haskell and LLM
coding agents. It does so by providing operations to surface the right
information required at a given stage: documentation, build status,
diagnostics, etc.

Like similar tools (`ghcid`, `ghciwatch`), it builds the code continuously on
every change, presents diagnostics, and runs the tests afterwards. However,
`tricorder` offers other advantages:

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
- **Multi-package projects** - In a `cabal.project` workspace, `tricorder`
  discovers every package's components automatically, building and running
  tests across all of them — no manual target configuration needed.
- **Project context** - Tools like `tricorder source Some.Module` will attempt
  to find and provide the source code for a given dependency from disk, which
  allows exploring library APIs more easily.
- **Machine-readable output** - Using `tricorder status --json` we can get
  build information in a format appropriate for programmatic usage.

## Installing with cabal

`tricorder` is published on
[Hackage](https://hackage.haskell.org/package/tricorder). With a GHC and
`cabal` toolchain available, install the executable from source:

```bash
cabal update
cabal install tricorder
```

This builds and installs the `tricorder` binary into cabal's install directory
(typically `~/.local/bin`, or `~/.cabal/bin` on older setups); make sure it is
on your `PATH`.

`tricorder` runs on both Linux and macOS.

### GHC 9.14 support

Currently, multiple of our dependencies do not support GHC 9.14, and as such we
are not able to officially support 9.14 just yet. But stay tuned, as we are
eager to utilize [the new multi-home features](https://www.youtube.com/watch?v=0tOciI7lMEE)!

## Using with Nix

See [Using with Nix](./docs/using-with-nix.md)

## Using with Claude Code

See [Using with Claude Code](./docs/using-with-claude-code.md)

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
nix flake new -t github:atelier-hub/tricorder#canvas ./my-service

# …or into the current (empty) directory:
nix flake init -t github:atelier-hub/tricorder#canvas
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
