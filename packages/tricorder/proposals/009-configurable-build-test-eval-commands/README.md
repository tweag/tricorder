# Configurable Build/Test/Eval Commands — Work Package

## High-level Description

Tricorder currently resolves a single `Command` (a REPL kind, a list of
arguments, and a list of targets) that is used, with varying degrees of
fidelity, to build the project, run test suites, and evaluate eval comments.
In practice the three uses diverge sharply:

- **Build** honors the user-configured `command` (a full override string) and
  `targets`.
- **Test** (`Tricorder.Daemon.TestRunner.mkTestCommand`) only reuses the
  resolved REPL kind — any custom arguments in `command` (e.g.
  `--enable-multi-repl`, project-specific `--ghc-options`) are silently
  dropped, and there is no way to configure test-only arguments.
- **Eval** (`Tricorder.Daemon.EvalCommentRunner.runFileEvals`) also only
  reuses the REPL kind, with no arguments and no configurability at all.

There is no supported way to give the test runner or the eval runner extra
flags, a different `--builddir`, or any other override independent of the
build command — even though these three phases legitimately need different
flags (for example: `--enable-multi-repl` only matters for build/load, and
memory-limit RTS flags are test-only today).

This proposal introduces three independently configurable command sections —
`build`, `test`, `eval` — each accepting a `command_template` string that
Tricorder substitutes the resolved target(s) into, plus per-section
`targets` and `extra_auto_arguments`. The `command_template` name signals that
it's completed by Tricorder before use, not a literal shell command — the
variable it understands is `{targets}` (plural) for `build`, since one
invocation covers every target, and `{target}` (singular) for `test` and
`eval`, since each invocation runs against exactly one target. `extra_auto_arguments`
and `command_template` are effectively mutually exclusive — `extra_auto_arguments`
only applies to Tricorder's automatically resolved command, and is ignored
(with a warning) once `command_template` is set, since anything it could add
can already be written directly into `command_template`. The existing
`command`, `targets`, and `test_targets` keys keep working, deprecated in
favor of the new sections.

**Deliverables:**

- This proposal (`README.md`, `design.md`, `spec.md`).
- New `build` / `test` / `eval` sections in `.tricorder.yaml`'s `session` map,
  each with `command_template` (template string), `targets`, and
  `extra_auto_arguments`.
- REPL kind resolution (`Tricorder.Session.Command.Repl`) decoupled from
  parsing the legacy `command` string, so it is available uniformly to build,
  test, and eval command resolution.
- Deprecation warnings (logged once per session load) when `command`,
  `targets`, or `test_targets` are used, naming their replacement.
- A warning when a section's `extra_auto_arguments` is set alongside a custom
  `command_template` for that section, since it is then silently ignored.
- Updated `docs/configuring-tricorder.md`.

---

## Core Objectives

- `build`, `test`, and `eval` commands can each be overridden independently,
  as a template string containing a placeholder that Tricorder fills with
  the resolved target(s), rendered according to the active REPL kind:
  `{targets}` (plural) for `build`, `{target}` (singular) for `test` and
  `eval`, matching how many targets each invocation actually runs against.
- `build` and `test` targets are independently configurable
  (`build.targets`, `test.targets`); `eval` targets are always the single
  module being evaluated and are not user-configurable. Unlike
  `command_template`, `targets` remains in effect even when
  `command_template` is custom, via `{targets}`/`{target}`.
- Each section accepts `extra_auto_arguments`, appended to the rendered
  _automatically resolved_ command — ignored, with a warning, once that
  section's `command_template` is set, since a custom `command_template`
  can already express anything `extra_auto_arguments` could add.
- REPL kind (`StackMulti` / `Stack` / `Cabal` / `Unknown`) is resolved once
  per session, from the filesystem, independently of whether any command is
  user-overridden, and used both to pick automatically resolved templates
  and to render `{targets}`/`{target}` (Stack's single-package mode needs
  bare component names; every other kind needs fully qualified targets).
- `command`, `targets`, and `test_targets` remain functional and map onto
  `build.command_template`, `build.targets`, and `test.targets`
  respectively, with a logged deprecation notice.

---

## Metrics for Success

- Existing `.tricorder.yaml` files using `command` / `targets` /
  `test_targets` continue to resolve to the same effective build command as
  before this change, with a deprecation warning logged.
- A project can set `test.extra_auto_arguments: ["--ghc-options=-Wall"]` and see
  that flag applied only to test runs, not to build or eval.
- A project that sets both `test.command_template` and `test.extra_auto_arguments`
  sees a warning and `test.extra_auto_arguments` has no effect on the rendered
  command.
- A project can set `eval.command_template` to a template using a different
  `--builddir` than build, and eval comments still evaluate correctly.
- Unit tests cover: template substitution (placeholder present/absent),
  per-repl-kind target rendering for each of the three command forms, and the
  full backward-compatibility mapping from deprecated keys.

---

## Classification

- **New initiative or continuation of existing:** Continuation — extends
  `Tricorder.Session.Command` and `Tricorder.Session.Config`.
- **Primary nature:** Technical.

---

## Milestones

### Milestone 1 — Config schema and REPL resolution

**Deliverables:**

- `CommandConfig` (`command_template`, `targets`, `extra_auto_arguments`) added to
  `Tricorder.Session.Config`, nested under `build` / `test` / `eval`.
- `resolveRepl` extracted from the current `useStack` / `useMultiCabal` /
  `stackReplKind` probing, independent of any `command` string.
- Deprecated `command`, `targets`, `test_targets` kept on `Config`, mapped
  onto the new sections per the precedence rules in `spec.md`.

**Acceptance criteria:** existing session-resolution tests pass unmodified
against the deprecated keys; new tests cover the new sections.

### Milestone 2 — Template rendering for build, test, eval

**Deliverables:**

- `{targets}`/`{target}` placeholder substitution, reusing per-repl-kind
  target rendering rules.
- `TestRunner.mkTestCommand` and `EvalCommentRunner.runFileEvals` updated to
  use the resolved `test`/`eval` templates and arguments instead of building
  a bare `Command` from only the REPL kind.

**Acceptance criteria:** test and eval runs pick up `test.extra_auto_arguments` /
`eval.extra_auto_arguments` (when `command_template` is unset) and a custom
`test.command_template` / `eval.command_template`.

### Milestone 3 — Docs and deprecation warnings

**Deliverables:**

- `docs/configuring-tricorder.md` updated with the new sections and a
  deprecation note on the old keys.
- `Log.warn` deprecation messages wired into `loadSession`.
- `Log.warn` wired into `loadSession` for a user-supplied
  `test.command_template` or `eval.command_template` that contains neither
  `{target}` nor `\{target}`.
- `Log.warn` wired into `loadSession` for each of `build`/`test`/`eval` when
  that section's `extra_auto_arguments` is set alongside a custom
  `command_template`.

**Acceptance criteria:**

- Loading a config with `command`/`targets`/`test_targets` set logs one
  warning per deprecated key used, naming its replacement.
- Loading a config with `test.command_template: "cabal repl test:foo"` (no
  placeholder) logs a warning naming `test.command_template`; the same for
  `eval.command_template` logs a warning naming `eval.command_template`.
- Loading a config with `build.command_template` missing `{targets}` logs
  no warning.
- Loading a config with both `build.command_template` and
  `build.extra_auto_arguments` set (or the equivalent for `test`/`eval`) logs a
  warning naming that section, and the rendered command does not include
  `extra_auto_arguments`.

---

## Notes

`command` / `targets` / `test_targets` are removed no earlier than 3 major
(PVP `0.8`) version bumps after the release that ships their deprecation
warning — see `design.md`'s Backward Compatibility section.
