# Design: Configurable Build/Test/Eval Commands

## Status

Implemented. See `README.md` for the work package. Low-level contracts in
`spec.md`.

---

## Problem

Tricorder models exactly one `Command` (`Tricorder.Session.Command.Command`:
a `Repl`, a list of `arguments`, a list of `targets`), resolved once per
session by `resolveCommand`. It is used, unevenly, in three places:

1. **Build.** `session.command` is rendered wholesale (`Command.render`) and
   fed to `Process.shell` to spawn the long-lived GHCi session
   (`GhciProcess.withGhciProcess`). This is the one place the full `Command`
   — REPL prefix, resolved/custom arguments, and targets — is respected.

2. **Test.** `Tricorder.Daemon.TestRunner.mkTestCommand` builds a *new*
   `Command` from scratch, reusing only `session.command.repl`. It adds a
   memory-limit RTS flag (`--ghc-options`/`--repl-options` depending on REPL
   kind) and a single test target. Any arguments the user put in `command` —
   `--enable-multi-repl`, project-specific flags, a custom `--builddir` — are
   silently absent from every test invocation.

3. **Eval.** `Tricorder.Daemon.EvalCommentRunner.runFileEvals` does the same:
   `Command repl [] [Target.Bare moduleName]`, no arguments at all.

Two independent problems follow from this:

- **No independent configurability.** There is no way to give test runs or
  eval runs their own flags. A `--repl-options "+RTS -N4 -RTS"` needed only
  for tests, or a `--builddir` that differs between build and eval, cannot be
  expressed.
- **REPL-kind-dependent target rendering is entangled with `command`
  parsing.** `resolveCommand` infers `Repl` two different ways depending on
  whether `command` is set: by pattern-matching the leading words of the
  user's `command` string (`"stack" : "repl" : args -> ...`) when set, or by
  filesystem probing (`useStack`, `useMultiCabal`, `stackReplKind`) when not.
  A custom `command` that doesn't start with a recognized prefix falls to
  `Unknown`, which still renders targets via `Target.renderTarget` (the
  Cabal-shaped rendering) — silently wrong if the custom command is
  Stack-flavored but phrased unusually. There's exactly one `Repl` value in
  play; every consumer (target rendering, memory-limit flag selection) reads
  it off `session.command.repl`, so getting it right in one place matters for
  build, test, and eval alike.

Both are the target of this proposal: separate, independently overridable
command *templates* for build/test/eval, and a REPL kind resolution that is
authoritative and available regardless of whether the user has overridden any
of the three commands.

---

## Approach

### One REPL resolution, shared by all three forms

Extract `resolveRepl :: (FileSystem :> es) => ProjectRoot -> Eff es Repl`
from the current `useStack` / `useMultiCabal` / `stackReplKind` filesystem
probing (`stack.yaml` present → `stackReplKind`; else `cabal.project` or
`*.cabal` files present → `Cabal`; else `Cabal` fallback). This becomes the
single source of truth for `Repl`, resolved once per session and used
identically whether or not the user has set `build.command_template`,
`test.command_template`, or `eval.command_template`. `Unknown` is dropped as
a resolution outcome — every real
project is Stack or Cabal-shaped by the time it reaches this code — and kept
only as a documented internal fallback for constructing a `Command` value
directly in tests.

This is a behavior change for users who today rely on a `command` string like
`my-wrapper-script --repl` that doesn't start with `stack`/`cabal`: their
target rendering currently falls to `Unknown` (Cabal-shaped rendering,
arguments dropped). Under the new resolution their targets render according
to the *actual* filesystem-detected REPL kind instead, which is strictly more
correct for the common case (a wrapper around `cabal repl` or `stack ghci`).
See Trade-offs.

### `CommandConfig`: one shape, three sections

```yaml
session:
  build:
    command_template: "cabal repl --enable-multi-repl {targets}"
    targets: [lib:foo, exe:bar]
    extra_auto_arguments: []
  test:
    command_template: "cabal repl {target}"
    targets: [test:foo]
    extra_auto_arguments: ["--repl-options=-fno-code"]
  eval:
    command_template: "cabal repl {target}"
    extra_auto_arguments: []
```

`build`, `test`, and `eval` each accept the same `CommandConfig` shape
(`command_template`, `targets`, `extra_auto_arguments`) for schema uniformity, but
`eval.targets` is documented as ignored: eval always evaluates comments in
the context of whichever single module is currently loaded, so there is no
static target list to configure. See `spec.md` for the full field-by-field
contract and the rationale for keeping the shape uniform anyway.

Fields are named to make the relationship between them legible from the
config alone, without needing the docs open:

- `command_template` — not `command` — because the value is not a literal
  shell command; it's a string Tricorder completes before use. The name is
  meant to prompt a reader to go find out what it can be completed *with*
  (the placeholder documented below), rather than assume they can paste in
  an arbitrary command verbatim and be done.
- `extra_auto_arguments` — not `arguments` — because it only ever extends
  Tricorder's *automatically* resolved command, never a `command_template`
  the user supplied themselves. See the exclusivity discussion below for why
  the field existing at all is contingent on `command_template` being unset.

`command_template` is a *template string*: a shell command containing a
literal placeholder, which Tricorder replaces with the REPL-kind-rendered
target(s) before the whole string is handed to `Process.shell`. The
placeholder name differs by section, matching how many targets one
invocation actually runs against: `build` runs once against every
configured/auto-detected target, so its placeholder is `{targets}`
(plural); `test` and `eval` each spawn one process per target — one test
suite, one module being evaluated — so their placeholder is `{target}`
(singular). Using `{targets}` in a `test`/`eval` template (or `{target}` in
a `build` template) is not an error, but it also isn't recognized —
substitution only fires for the placeholder that section understands (see
`spec.md`). If a section's `command_template` is unset, Tricorder falls back
to an automatically resolved template chosen from the resolved `Repl`
(mirroring today's `detectCommand`/`useStack`/`useMultiCabal`/`fallback`
defaults for build, and today's `mkTestCommand`/`runFileEvals` defaults for
test/eval).

`extra_auto_arguments` is appended after the rendered *automatically resolved*
template — not spliced through a placeholder, and not available once
`command_template` is custom. The name says why: anything `extra_auto_arguments`
could add, a custom `command_template` can already express directly as more
text in the string, so the field only pulls weight when extending what
Tricorder would have generated automatically (add a flag, keep the
REPL-kind-appropriate prefix and `--builddir` Tricorder would otherwise
compute for you). `command_template` and `extra_auto_arguments` are therefore
effectively mutually exclusive: if `command_template` is set,
`extra_auto_arguments` is ignored, and Tricorder logs a warning when both are
present, since the combination is most likely a misunderstanding rather than
intentional (see `spec.md`). `targets` is not part of this exclusivity — it
composes with a custom `command_template` via `{targets}`/`{target}`, since
target auto-detection isn't something a user can replicate by hand the way a
flag is.

This composes with Tricorder-managed arguments (the memory-limit RTS flag —
see below), which are appended after whichever `arguments` the resolved
`Command` ends up carrying (the config's `extra_auto_arguments` when
`command_template` is unset, or none when it's custom).

A user-supplied `command_template` that contains neither its section's
placeholder (`{targets}` for build, `{target}` for test/eval) nor the
escaped form is accepted, not rejected — silently building "all targets
configured but never passed to the process" mirrors today's behavior for a
fully custom `command`, and there are legitimate uses (a template that
always builds a fixed target set typed out literally).

`test.command_template` and `eval.command_template` are checked for this and
warned about; `build.command_template` is not. `TestRunner` runs one process
per test target, and `EvalCommentRunner` runs one process per source file,
each re-rendering the same template — if the template has no `{target}`
placeholder, every invocation silently runs the exact identical command,
since the one thing that's supposed to vary between invocations (which
target/module) never gets substituted in. That's the case most likely to be
an accidental mistyped placeholder rather than a deliberate choice — for
`eval` in particular, a missing placeholder means every file's eval comments
get evaluated against whatever module the hardcoded command happens to load,
not the file actually being processed, which is a silent correctness bug,
not just a missed convenience. `build` doesn't share that failure shape:
its target list is typically "all" of the project's components already, and
build only runs once per session (not once per target), so a missing
`{targets}` there mirrors today's behavior for a fully custom `command` —
far more likely a deliberate fixed-target template than an oversight.
Tricorder logs a `Log.warn` at session-load time when `test.command_template`
or `eval.command_template` is user-supplied and lacks `{target}`. The
automatically resolved templates (see `spec.md`) all contain their section's
placeholder, so the warning never fires for a project that hasn't overridden
either.

### Backward compatibility

`command`, `targets`, and `test_targets` remain on `Config`, marked
deprecated. They fold into the new sections at session-load time:

| Deprecated key | Maps onto | Notes |
|---|---|---|
| `command` | `build.command_template` | Only ever affected build; test/eval already ignored it. |
| `targets` | `build.targets` | Also still the fallback source for `test.targets` when neither `test.targets` nor `test_targets` is set, preserving today's "targets starting with `test:`" derivation. |
| `test_targets` | `test.targets` | |

If both a deprecated key and its replacement are set, the new key wins (an
explicit `build.command_template` overrides a stray `command`). Whenever a deprecated
key is present in the loaded config — regardless of whether it was
overridden — `loadSession` logs one `Log.warn` naming the key and its
replacement, so migration is visible without breaking existing setups.

`command`, `targets`, and `test_targets` are removed no earlier than **3
major (PVP `A.B`) version bumps** after the release that ships this
deprecation warning. E.g. if the warning ships in `0.5.0.0`, the keys may be
removed starting at `0.8.0.0`. This gives users at least three feature
releases' worth of notice, consistent with the deprecation warning being
visible on every affected session load in the interim.

### Test's Tricorder-managed arguments stay Tricorder-managed

The memory-limit RTS flag (`--ghc-options "+RTS -M<size> -RTS"` for
Stack/StackMulti, `--repl-options "+RTS -M<size> -RTS"` for Cabal) is
computed from `test_memory_limit`, not from `test.extra_auto_arguments`, and is
unaffected by the `command_template`/`extra_auto_arguments` exclusivity above: it
is appended by `renderTest` (see "`BuildCommand`/`TestCommand`/
`EvalCommand`, not bare `Text`" below) after whichever `arguments` the
resolved `CommandTemplate` already carries (`test.extra_auto_arguments` when
`test.command_template` is unset, none when it's custom) —
`extra_auto_arguments` is for user-supplied flags on the automatically resolved
command, not a place to hand-roll the memory limit, and the memory limit
flag applies regardless of whether `test.command_template` is set.

### `CommandTemplate` vs. rendered `Text`

Early drafts of this proposal (and the implementation up through the first
few iterations) used a single `Command` type carrying `repl`, `template`,
`arguments`, and `targets` together, with `render :: Command -> Text`
reading `targets` off the value. That's structurally misleading for
`test`/`eval`: neither knows its target at resolution time (`resolveTestCommand`/
`resolveEvalCommand` are called once per session, before any test target or
source file is in scope), so both set `targets = []` and relied on
`TestRunner`/`EvalCommentRunner` to patch in the real value later via a
record update, once per test target / source file. A type that's
legitimately empty until some later, separate step overwrites it isn't
telling the truth about what it holds.

The fix: `CommandTemplate` drops `targets` entirely, and `render` takes it
as an explicit parameter — `render :: CommandTemplate -> [Target] -> Text`.
A `CommandTemplate` is now honestly "not yet rendered, and structurally
incapable of pretending otherwise"; a `Text` is honestly "fully rendered,
nothing left to fill in." `TestRunner.mkTestCommand` and
`EvalCommentRunner.runFileEvals` now render immediately, at the point they
already have the one target in hand, rather than deferring via a
placeholder field. See `spec.md`'s "Template/rendered-command separation"
for the full type-level and call-site detail, including why this also lets
`Tricorder.Daemon.GhciSession.GhciProcess` (and the layers above it) drop
their dependency on `Tricorder.Session.Command` altogether — they only ever
needed the rendered string.

### `BuildCommand`/`TestCommand`/`EvalCommand`, not bare `Text`

A rendered command being plain `Text` still leaves a gap: nothing stops a
`Text` produced for one phase from being passed to another phase's
plumbing, or from being confused with any other string floating around the
daemon. `Text` says "fully rendered command," but not *which* command.

Three newtypes close that gap: `BuildCommand`, `TestCommand`, and
`EvalCommand`, each wrapping `Text` (with a `getXCommand` accessor,
following this codebase's existing `newtype Foo = Foo { getFoo :: X }`
convention — see `TestTimeout`, `WatchDirs`, `ReplBuildDir`). In place of
one `render`, there are three: `renderBuild`, `renderTest`, `renderEval`,
each returning its own phase's newtype. This is a genuine three-way split,
not just cosmetic renaming, because the three phases don't render
identically:

- `renderBuild :: CommandTemplate -> [Target] -> BuildCommand` — a plain
  wrap around the shared substitution logic. `build`'s target list can be
  arbitrarily long.
- `renderTest :: CommandTemplate -> Maybe ByteSize -> TestTarget ->
  TestCommand` — takes the memory limit directly and folds the
  Tricorder-managed RTS flag into `CommandTemplate.arguments` before
  rendering, rather than requiring the caller to compute that flag
  externally and hope it's remembered. This used to live in
  `TestRunner.mkTestCommand`, reaching back into `Command.render`; now it's
  the one place test rendering happens at all.
- `renderEval :: CommandTemplate -> [Target] -> EvalCommand` — a plain wrap,
  like build, but conceptually always a one-element target list (the module
  being evaluated).

The process-spawning layer (`Builder.with`, `GhciSession.withGhci`/
`withGhciWith`, `GhciProcess.withGhciProcess`) still takes plain `Text` —
it's genuinely phase-agnostic (it spawns whatever shell command it's given,
regardless of which phase produced it), so forcing it to pick one of
`BuildCommand`/`TestCommand`/`EvalCommand` would be a false constraint. Each
call site (`Tricorder.Daemon.Core`, `TestRunner.run`,
`EvalCommentRunner.run`) unwraps its own phase's newtype via `getXCommand`
immediately before handing the string to that shared plumbing — the newtype
boundary is exactly "resolution and phase-specific rendering," not "every
layer that happens to touch a rendered command."

`Tricorder.Daemon.TestRunner`'s own `TestCommand` (previously a
`newtype TestCommand = TestCommand Text` local to that module, produced by
`mkTestCommand`/`unsafeMkTestCommand`) is retired in favor of
`Tricorder.Session.Command.TestCommand` — there is no reason for two
same-named-but-different types, and `TestRunner`'s `RunTestSuite` effect
now takes the `Command`-module one directly.

---

## Alternatives Considered

### Keep a single `command`/`targets`, add per-phase `arguments` only

Add `test_arguments` / `eval_arguments` flat keys next to the existing
`command`/`targets`, without introducing template strings or nested
sections. This is a smaller change, but doesn't solve the actual ask: there
would be no way to give test or eval a different base command (a different
REPL invocation entirely, or a different `--builddir`), only extra flags
tacked onto Tricorder's own default. It also doesn't give the target-rendering
fix (decoupling REPL resolution from `command` parsing) anywhere natural to
live, since there'd still be only one `command` string to parse for REPL
hints.

### Placeholder syntax: positional argument list instead of string template

Instead of a `{targets}` placeholder inside a string, model `command` as a
list of argument tokens with a distinguished `Targets` marker (e.g. YAML
`command: [cabal, repl, --enable-multi-repl, "$targets"]`). This avoids
stringly-typed substitution but is a more invasive config-format change
(existing `command` is already a plain string that gets `words`-split) and
doesn't match the phrasing of the ask ("a template string"). Not pursued —
`\{targets}` (see below) covers the collision case string templating
raised.

### Resolve `Repl` per-form from each form's own `command_template` text

Keep parsing REPL hints from each of `build.command_template`/
`test.command_template`/`eval.command_template` independently, the way
today's code parses the deprecated `command`. Rejected because it
reintroduces the exact entanglement this proposal removes: three independent
parses of REPL kind that can disagree with each other and with the
filesystem, instead of one authoritative resolution shared by all three.

### Enforce `command_template`/`extra_auto_arguments` exclusivity at the schema level

Model `command_template` and `extra_auto_arguments` as a proper either/or in the
config shape (e.g. reject a section that sets both at parse time, or require
a tagged-union-style YAML shape) rather than "the field names say it, and a
warning catches the mistake." Rejected: this `Config`'s `FromJSON` is a
straightforward `WithDefaults (QuietSnake Config)` derivation, structurally
just a flat record; a true parse-time either/or would mean hand-writing a
custom `FromJSON` instance for `CommandConfig` (breaking the `WithDefaults`
recursive-merge defaulting described above) for a case that is at worst a
silent no-op, not a wrong or dangerous outcome. The rename plus a load-time
warning gets most of the clarity benefit — the field names alone tell you
when `extra_auto_arguments` stops applying — at a fraction of the implementation
cost.

### One universal `{targets}` placeholder for all three sections

Keep a single placeholder name across `build`/`test`/`eval`, documenting
that for `test`/`eval` it always resolves to a one-element list. Rejected:
the whole point of `command_template` (over the old `command`) is that
config field names should carry as much of the contract as possible without
sending the reader to the docs. `{targets}` in a template that is,
mechanically, invoked once per single target is actively misleading —
someone reading `test.command_template: "cabal repl {targets}"` has no
local reason to expect only one target ever lands there. Splitting the
placeholder by cardinality (`{targets}` where an invocation covers many,
`{target}` where it covers exactly one) costs one more exported name
(`targetPlaceholder` alongside `targetsPlaceholder` in
`Tricorder.Session.Command`) and is otherwise free — `Command.placeholder`
already has to be threaded through `resolveBuildCommand` /
`resolveTestCommand` / `resolveEvalCommand` regardless, since each already
resolves independently.

---

## Trade-offs

**Behavior change for custom `command` strings with an unrecognized
prefix.** Today, a `command` that doesn't start with `stack`/`cabal` resolves
to `Unknown` and renders targets in Cabal's fully-qualified form. Under this
proposal, `Repl` is always filesystem-resolved, so the same project now
renders targets according to whatever `resolveRepl` actually detects. This is
more correct for the realistic case (a wrapper script around `cabal repl` or
`stack ghci`), but is a behavior change worth calling out in the changelog.

**`eval.targets` exists in the schema but is inert.** Keeping `CommandConfig`
uniform across all three sections means `eval.targets` parses without error
but has no effect, which could confuse a user who sets it expecting per-file
control. Documented explicitly in `spec.md` and `configuring-tricorder.md`;
alternative (a separate, narrower config type for `eval` without `targets`)
was rejected as not worth the schema asymmetry for one field.

**Three-major-version deprecation window.** `command`/`targets`/`test_targets`
keep working, with a warning, until 3 PVP major (`A.B`) bumps after the
release that introduces the warning. Compatibility code (the mapping table in
`spec.md`) has to be carried across all of those releases, and removal has to
be tracked against version numbers rather than being a fire-and-forget change
— whoever ships the removal needs to check the deprecating release's version
against the current one.

**Two placeholder names instead of one.** `build.command_template` and
`test`/`eval.command_template` don't share a placeholder — writing
`{targets}` in a `test.command_template` (or `{target}` in a
`build.command_template`) silently does nothing rather than erroring, since
`hasPlaceholder`/`substitutePlaceholder` only look for the one placeholder
name the resolved `Command.placeholder` carries. This is a real footgun for
someone who copies a `build.command_template` example into `test`/`eval`
without adjusting the placeholder; mitigated by the missing-placeholder
warning (scoped to `test.command_template`/`eval.command_template` — see
above), which does fire in exactly that case, since the copied template's
`{targets}` doesn't count as `test`/`eval`'s `{target}` placeholder being
present. `build.command_template` has no equivalent check, so the same
mistake in reverse (copying a `test`/`eval` example into `build` without
switching `{target}` to `{targets}`) goes unwarned — accepted as a smaller
risk, since `build` is the one place a custom template dropping target
substitution entirely mirrors long-standing, expected behavior.
