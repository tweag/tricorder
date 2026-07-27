# Using with Claude Code

Tricorder ships a [Claude Code](https://claude.ai/code) plugin that gives
agents real-time GHCi build status via a skill.

## Install the plugin

Add the `atelier` marketplace to your Claude Code `settings.json` (either
project-level `.claude/settings.json` or user-level `~/.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": {
    "atelier": {
      "source": {
        "source": "github",
        "repo": "tweag/tricorder"
      }
    }
  },
  "enabledPlugins": {
    "tricorder@atelier": true
  }
}
```

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
