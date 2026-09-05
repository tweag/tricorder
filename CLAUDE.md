# Claude Code Plugin

The tricorder plugin provides a skill for checking build status from within Claude Code sessions.

See `.claude-plugin/tricorder/INSTALL.md` for installation instructions.

---

## Dependencies and `.cabal` files

**Never edit `*.cabal` files by hand — they are generated.** The source of
truth is the Nix/hpack setup, and a pre-commit hook (`nix-hpack`) regenerates
the `.cabal` files and fails the commit if a checked-in `.cabal` has drifted
from its source. Hand edits are reverted on the next regeneration.

- Version bounds live in `nix/package/dependencies.nix` (the `constraints` set).
- Each package declares which dependencies its components (internal libraries,
  executables, tests) use in that package's `package.nix`
  (e.g. `packages/tricorder/package.nix`).
- Modules are auto-discovered from the source tree — you do **not** list them.

To add or change a dependency:

1. If the package isn't already in `nix/package/dependencies.nix` `constraints`,
   add it there with a version bound.
2. Add the dependency name to the relevant component's dependency list in that
   package's `package.nix`.
3. Regenerate the `.cabal` files with `nix-hpack` (no args regenerates every
   package; or pass a package dir, e.g. `nix-hpack ./tricorder`).
4. Commit **both** the `package.nix` and the regenerated `.cabal`.

---

See `CONTRIBUTING.md` for project conventions and workflow (mostly relevant for bigger tasks).
