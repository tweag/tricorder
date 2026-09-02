---
name: tricorder
description: Check GHCi build status, compiler errors/warnings, or test results for this Haskell project. Use when asked to check the build, see errors/warnings, or run tricorder.
user-invocable: true
---

# Checking Build Status with tricorder

1. Check whether the `mcp__plugin_tricorder-mcp_tricorder__*` MCP tools are
   connected (provided by the `tricorder-mcp` plugin, if installed). If so,
   use them directly for this task and stop here — do not invoke the
   `tricorder-cli` skill.
2. Otherwise — the tools aren't available (e.g. `tricorder-mcp` isn't
   installed), or they error, hang, or return stale results — invoke the
   `tricorder-cli` skill. It has the full `tricorder` CLI reference.
