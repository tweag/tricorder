# tricorder-types

Shared domain types for [Tricorder](../tricorder/README.md) and
[Tricorder's MCP server](../tricorder-mcp/README.md).

`tricorder-types` intentionally has no dependency on `tricorder` itself, so
consumers that only need to construct or render these types — without pulling
in the full daemon, TUI, or build machinery — can depend on it directly.

## License

MIT — see [LICENSE](LICENSE).
