# Using with Claude Code

Tricorder ships a [Claude Code](https://claude.ai/code) plugin that gives
agents real-time GHCi build status via a skill.

## Install the plugins

Add the `tricorder` marketplace with in a `claude` session, and install the
plugins from there:

```bash
/plugin marketplace add tweag/tricorder
# For the skill-based approach to using Tricorder
/plugin install tricorder@tricorder
# For the MCP-based approach to using Tricorder
/plugin install tricorder-mcp@tricorder
```

If you have both plugins installed, your Claude agent will prefer to use the
MCP server, if it is available and functional. Otherwise, it falls back to the
purely skill-based approach.

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
