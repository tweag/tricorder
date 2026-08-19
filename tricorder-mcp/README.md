# tricorder-mcp

Model Context Protocol server for [Tricorder](../tricorder/README.md).

## Installation

`tricorder-mcp` needs to be downloaded or installed onto your machine before Claude or Copilot can use it.

### Hackage

Download or install from [Hackage](https://hackage.haskell.org/package/tricorder-mcp):

```bash
cabal install tricorder-mcp
# or
stack install tricorder-mcp
```

### GitHub release

Download and install from [GitHub releases](https://github.com/tweag/tricorder/releases), and place the binary in your `PATH`.

## Add MCP server to your agent

### With Claude

If you put `tricorder-mcp` in your `PATH`:

```bash
claude mcp add tricorder -- tricorder-mcp
```

Alternatively, if you want to refer to `tricorder-mcp` by an absolute path:

```bash
claude mcp add tricorder -- /path/to/tricorder-mcp
```

### With Copilot

Use the `/mcp add` command within Copilot, or use the CLI directly:

```bash
copilot mcp add tricorder -- tricorder-mcp
```

Alternatively, if you want to refer to `tricorder-mcp` by an absolute path:

```bash
copilot mcp add tricorder -- /path/to/tricorder-mcp
```

## Usage

Prompt your agent to use the `tricorder` MCP server whenever you want it to
perform some work. Alternatively, you can add it to your repo's `AGENT.md` to
ensure your agent always knows that the MCP server is available.

## Built on atelier

`tricorder-mcp` is built on the **atelier** toolkit, also developed in this repository:

- [`atelier-prelude`](https://github.com/tweag/tricorder/tree/main/atelier-prelude) — relude-based prelude with Effectful conventions
- [`atelier-core`](https://github.com/tweag/tricorder/tree/main/atelier-core) — foundational effects and utilities
- [`atelier-db`](https://github.com/tweag/tricorder/tree/main/atelier-db) — relational database effect (Hasql/Rel8)
- [`atelier-testing`](https://github.com/tweag/tricorder/tree/main/atelier-testing) — database-backed test utilities
- [`atelier-monitoring`](https://github.com/tweag/tricorder/tree/main/atelier-monitoring) - observability and monitoring effects and utilities

## License

MIT — see [LICENSE](LICENSE).
