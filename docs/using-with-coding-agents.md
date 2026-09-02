# Using with coding agents

Tricorder ships a [Claude Code](https://claude.ai/code) plugin that gives
agents real-time GHCi build status via a skill.

## Install the plugins

The easiest alternative for using Tricorder with a coding agent is to add the
`tricorder` marketplace, and install the plugins from there.

### Claude Code

```bash
/plugin marketplace add tweag/tricorder
# For the skill-based approach to using Tricorder
/plugin install tricorder@tricorder
# For the MCP-based approach to using Tricorder
/plugin install tricorder-mcp@tricorder
```

### Copilot

```bash
copilot plugin marketplace add tweag/tricorder
# For the skill-based approach to using Tricorder
copilot plugin install tricorder@tricorder
# For the MCP-based approach to using Tricorder
copilot plugin install tricorder-mcp@tricorder
```

### Grok

```bash
grok plugin marketplace add tweag/tricorder
# For the skill-based approach to using Tricorder
grok plugin install tricorder@tricorder
# For the MCP-based approach to using Tricorder
grok plugin install tricorder-mcp@tricorder
```

### Cursor

See [Cursor's documentation on how to install a plugin][cursor-install-plugin].

### Skill or MCP?

If you have both plugins installed, your Claude agent will prefer to use the
MCP server-based skill, `tricorder-mcp`, if it is available and functional.
Otherwise, it falls back to the purely skill-based approach.

## (Optional) Allow tricorder commands

The skill uses `tricorder status` and `tricorder status --wait`. Add them to
your `permissions.allow` list to avoid being prompted on every invocation:

```json
{
  "permissions": {
    "allow": [
      "Bash(tricorder status)",
      "Bash(tricorder status --wait)",
      "Skill(tricorder:tricorder)"
    ]
  }
}
```

Once enabled, Claude Code will automatically check GHCi build status and
diagnostics when working on Haskell code in projects running the tricorder
daemon.

[cursor-add-marketplace]: https://cursor.com/docs/plugins#add-a-team-marketplace
[cursor-install-plugin]: https://cursor.com/docs/plugins#installing-plugins
