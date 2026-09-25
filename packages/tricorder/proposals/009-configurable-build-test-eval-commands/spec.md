# Spec: Configurable Build/Test/Eval Commands

## Status

Implemented. Read `design.md` first for context and rationale.

---

## Config Schema

New nested sections under `session`, alongside the existing keys:

```yaml
session:
  build:
    command_template: string    # optional; template string, see below
    targets: [string]           # optional; default []
    extra_auto_arguments: [string]    # optional; default []; ignored if `command_template` is set
  test:
    command_template: string
    targets: [string]
    extra_auto_arguments: [string]
  eval:
    command_template: string
    extra_auto_arguments: [string]    # `targets` accepted but ignored, see below
```

All three sections are optional; an absent section is equivalent to
`{command_template: null, targets: null, extra_auto_arguments: []}`.

Field names are chosen so the relationship between them is visible without
consulting docs: `command_template` (not `command`) signals it's completed
by Tricorder before use, not a literal shell command — prompting a reader to
look up what it can be completed with (`{targets}`/`{target}`, see below).
`extra_auto_arguments` (not `arguments`) signals it only extends Tricorder's
*automatically* resolved command — see "Default-arguments exclusivity"
below for when that stops being true. `targets` is not subject to that
exclusivity: it remains in effect even when `command_template` is custom.

`Tricorder.Session.Config`:

```haskell
data CommandConfig = CommandConfig
    { commandTemplate :: Maybe Text
    , targets         :: Maybe [Text]
    , extraAutoArguments   :: [Text]
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake CommandConfig

instance Default CommandConfig where
    def = CommandConfig { commandTemplate = Nothing, targets = Nothing, extraAutoArguments = [] }

data Config = Config
    { build :: CommandConfig
    , test :: CommandConfig
    , eval :: CommandConfig
    , watchDirs :: [FilePath]
    , watchExclusionPatterns :: [Text]
    , replBuildDir :: FilePath
    , testTimeout :: Int
    , generateWithHpack :: Bool
    , testMemoryLimit :: Maybe Text
    , hooks :: Maybe Hooks
    , idleTimeoutSeconds :: Int
    , -- DEPRECATED, see "Backward Compatibility Mapping" below.
      command :: Maybe Text
    , targets :: [Text]
    , testTargets :: Maybe [Text]
    }
```

(`FromJSON` derivation unchanged from today: `QuietSnake` for
camelCase-to-snake_case field names, `WithDefaults` to fill in missing keys
from `Default`.)

---

## Template Placeholder Syntax

Each resolved `Command` carries a `placeholder :: Text` — the bare
placeholder name (no braces) its `template` is checked against. This is not
user-configurable; it follows from the section:

| Section | `placeholder` | Rationale |
|---|---|---|
| `build` | `targets` (i.e. `{targets}`, plural) | One invocation covers every configured/auto-detected target at once. |
| `test` | `target` (i.e. `{target}`, singular) | One process is spawned per test target; each invocation runs against exactly one. |
| `eval` | `target` (i.e. `{target}`, singular) | One process is spawned per source file; each invocation evaluates exactly one module. |

A `command_template` value is plain shell text with zero or more occurrences
of the literal substring `{<placeholder>}` (using that section's
`placeholder`), and zero or more occurrences of the escaped form
`\{<placeholder>}`. `{targets}` in a `test`/`eval` template, or `{target}`
in a `build` template, is not the placeholder that section checks for — it
is left untouched, exactly as any other non-matching text would be.

- Every unescaped occurrence of the section's placeholder is replaced with
  the REPL-kind-rendered target(s), space-joined (see "Per-Repl-Kind Target
  Rendering") — for `test`/`eval`, this is always a one-element list, so the
  substitution is just that one rendered target.
- `\{<placeholder>}` is a literal escape: it renders as `{<placeholder>}` in
  the final command, with no target substitution. Only the leading brace
  needs escaping (`\{`) — the text after it is not itself special, so the
  closing brace does not need its own escape.
- If the section's placeholder (unescaped or escaped) does not occur in the
  template at all, the resolved target(s) are computed (for
  logging/consistency) but never inserted into the command — equivalent to
  today's behavior when a fully custom `command` is given. This is
  accepted, not rejected, but see "Missing-placeholder warning" below.
- The name `command_template` (not `command`) is chosen precisely so this
  placeholder syntax is discoverable: a reader who assumes it's a literal
  shell command has no reason to look for a placeholder at all.
- Empty target list + placeholder present → the placeholder is replaced
  with the empty string; surrounding whitespace is collapsed by the final
  `T.words . T.unwords` pass so the rendered command has no doubled spaces.
  (In practice this only affects `build`, whose target list can be
  legitimately empty before the "all" fallback applies; `test`/`eval`
  always substitute exactly one target.)

### Missing-placeholder warning

At session-load time, for each of `test.command_template` and
`eval.command_template` that is user-supplied (not the automatically
resolved default), Tricorder checks whether the template contains
`{target}` or `\{target}` at all — note: `{target}` (singular), `test`'s
and `eval`'s shared placeholder, not `{targets}`. If it contains neither,
it logs, at `warn` level:

```
"session.test.command_template has no {target} placeholder — every test invocation will run the same command."
"session.eval.command_template has no {target} placeholder — every eval invocation will run the same command."
```

This check runs once per session load/reload, independently for `test` and
`eval`, on the raw template text, before any substitution. It never fires
when a section's `command_template` is left unset and falls back to the
automatically resolved default (which always contains `{target}`; see
"Default Templates Per Repl Kind" below). Note that neither `test` nor
`eval` has a legacy fallback — the deprecated `command` key only ever maps
onto `build.command_template` (see "Backward Compatibility Mapping"), so
this check is unaffected by it. `build.command_template` is never checked
for a missing placeholder — see design.md for why the check is scoped to
`test`/`eval` and not `build`.

Substitution is a two-pass replace so that `\{<placeholder>}` is never
itself matched by the unescaped-placeholder pass: first swap
`\{<placeholder>}` out for a sentinel that cannot appear in a template,
substitute the real `{<placeholder>}` occurrences, then swap the sentinel
back in as the literal text `{<placeholder>}`.

```haskell
targetsPlaceholder, targetPlaceholder :: Text
targetsPlaceholder = "targets"  -- build
targetPlaceholder = "target"    -- test, eval

renderTemplate :: Text -> Text -> [Text] -> Text
renderTemplate placeholderName template renderedTargets =
    T.replace escapeSentinel bareholder
        $ T.replace bareholder (T.unwords renderedTargets)
        $ T.replace ("\\" <> bareholder) escapeSentinel template
  where
    bareholder = "{" <> placeholderName <> "}"
    -- Must not itself contain the literal substring "{<placeholderName>}" —
    -- the unescaped-placeholder pass above would otherwise match inside it
    -- and corrupt the sentinel before the swap-back pass runs.
    escapeSentinel = "\NUL__escaped_" <> placeholderName <> "_placeholder__\NUL"
```

### Default-arguments exclusivity

For each of `build`/`test`/`eval`, `extra_auto_arguments` only contributes to the
resolved `Command.arguments` when that section resolves to the
automatically resolved template — i.e. when `command_template` is unset for
that section (for `build`, this also accounts for the deprecated top-level
`command`: see "Backward Compatibility Mapping"). When a custom template is
in play, `Command.arguments` is `[]` for that section; the config's
`extra_auto_arguments` value is not consulted at all when rendering.

```haskell
resolvedArguments :: Maybe Text -> [Text] -> [Text]
resolvedArguments customTemplate configuredextraAutoArguments =
    maybe configuredextraAutoArguments (const []) customTemplate
```

At session-load time, for each of `build`/`test`/`eval`, if that section's
custom-template source (`build.command_template <|> command` for build;
`test.command_template`/`eval.command_template` for the other two) is
`Just` and `extra_auto_arguments` is non-empty, Tricorder logs, at `warn` level:

```
"session.<section>.command_template is set; session.<section>.extra_auto_arguments is ignored (it only applies to Tricorder's automatically resolved command)."
```

with `<section>` substituted for `build`, `test`, or `eval`. This check runs
once per session load/reload, independently for each section, and is
orthogonal to the missing-placeholder warning above (a `test.command_template`
that is both missing `{target}` and paired with a non-empty
`test.extra_auto_arguments` triggers both warnings).

---

## REPL Resolution

```haskell
resolveRepl :: (FileSystem :> es) => ProjectRoot -> Eff es Repl
```

Replaces the filesystem-probing halves of today's `useStack`,
`useMultiCabal`, and `stackReplKind`, unconditionally (no longer gated behind
"only if `command` is unset"):

1. If `<project-root>/stack.yaml` exists: read and decode it. If its
   top-level `packages` key is an array with more than one element, resolve
   `StackMulti`; otherwise `Stack`. (Identical to today's
   `stackReplKind`.)
2. Else if `<project-root>/cabal.project` exists, or any `*.cabal` file is
   present at the project root: resolve `Cabal`.
3. Else: resolve `Cabal` (fallback — matches today's `fallback` case).

`Unknown` is removed from the resolvable outcomes of `resolveRepl` (it
remains a constructor of `Repl` only for directly-constructed `Command`
values in tests/fixtures).

This is called once per `loadSession`/reload, independent of whether any of
`build.command_template` / `test.command_template` / `eval.command_template`
is set.

---

## Per-Repl-Kind Target Rendering

Unchanged from today's `Command.render` logic, now a standalone function
consumed by all three forms:

```haskell
renderTargetsFor :: Repl -> [Target] -> [Text]
renderTargetsFor = \case
    Stack      -> List.nub . fmap Target.componentName
    StackMulti -> List.nub . fmap Target.renderTarget
    Cabal      -> fmap Target.renderTarget
    Unknown    -> fmap Target.renderTarget
```

---

## Default Templates Per Repl Kind

Used when a section's `command_template` is `Nothing`. `<dir>` is
`session.replBuildDir` (existing `repl_build_dir` config, unchanged).

| Form | Repl | Default `command_template` |
|---|---|---|
| build | Stack / StackMulti | `stack ghci {targets}` |
| build | Cabal (cabal.project or multiple `.cabal` files present) | `cabal repl --enable-multi-repl --builddir <dir> {targets}` |
| build | Cabal (fallback, single package) | `cabal repl --builddir <dir> {targets}` |
| test | Stack / StackMulti | `stack ghci {target}` |
| test | Cabal | `cabal repl {target}` |
| eval | Stack / StackMulti | `stack ghci {target}` |
| eval | Cabal | `cabal repl {target}` |

These match the command strings produced by today's `detectCommand`
(build), `mkTestCommand` (test), and `runFileEvals` (eval) before any
`extra_auto_arguments` are appended — this proposal does not change default
behavior for projects that configure nothing.

---

## Resolution Algorithm

Per session load (and per reload):

```
repl = resolveRepl(projectRoot)

buildTargetsCfg = build.targets `orElse` legacyTargets `orElse` []
buildTargets    = if null buildTargetsCfg
                     then autoDetectAllComponents(cabalFiles)
                     else parseTarget <$> buildTargetsCfg

buildCustomTemplate = build.command_template `orElse` legacyCommand
buildTemplate        = buildCustomTemplate `orElse` defaultTemplateFor(build, repl)
buildArguments       = resolvedArguments(buildCustomTemplate, build.extra_auto_arguments)

testTargetsCfg = test.targets `orElse` legacyTestTargets `orElse` projectTestTargets(buildTargets)
testTemplate   = test.command_template `orElse` defaultTemplateFor(test, repl)
testArguments  = resolvedArguments(test.command_template, test.extra_auto_arguments)
-- memory-limit flag appended separately, per test run, regardless of testArguments

evalTemplate   = eval.command_template `orElse` defaultTemplateFor(eval, repl)
evalArguments  = resolvedArguments(eval.command_template, eval.extra_auto_arguments)
-- eval.targets and eval's legacy fallback do not exist; targets are always
-- the single module being evaluated, resolved per-file at eval time.
```

`orElse` is left-biased `Maybe`/empty-list choice (`a <|> b`, or `if null a
then b else a` for lists). `legacyCommand`/`legacyTargets`/`legacyTestTargets`
are `cfg.command`/`cfg.targets`/`cfg.testTargets` respectively.
`resolvedArguments` is defined in "Default-arguments exclusivity" above:
`Just` a custom template means the section's `extra_auto_arguments` is
dropped entirely, not just left out of the template substitution.

Rendering a concrete command for a given invocation — see "Template/
rendered-command separation" below for why `[Target]` (and, for test, the
memory limit) are parameters to a phase-specific render function, rather
than fields of whatever value carries `repl`/`template`/`arguments`, and
why there are three render functions (each returning its own phase's
newtype) instead of one generic one:

```haskell
renderBuild :: CommandTemplate -> [Target] -> BuildCommand
renderBuild commandTemplate targets =
    BuildCommand $ renderText commandTemplate targets

renderTest :: CommandTemplate -> Maybe ByteSize -> TestTarget -> TestCommand
renderTest commandTemplate mMemoryLimit target =
    TestCommand
        $ renderText
            commandTemplate {arguments = commandTemplate.arguments <> memoryLimitFlag commandTemplate.repl mMemoryLimit}
            [getTestTarget target]

renderEval :: CommandTemplate -> [Target] -> EvalCommand
renderEval commandTemplate targets =
    EvalCommand $ renderText commandTemplate targets

-- Shared substitution logic; not exported (see "Template/rendered-command
-- separation" below).
renderText :: CommandTemplate -> [Target] -> Text
renderText commandTemplate targets =
    T.unwords
        [ renderTemplate commandTemplate.placeholder commandTemplate.template
            (renderTargetsFor commandTemplate.repl targets)
        , T.unwords commandTemplate.arguments
        ]
```

- **Build**: `renderBuild (CommandTemplate repl buildTemplate buildArguments
  targetsPlaceholder) buildTargets`, once per session (re-rendered on
  reload).
- **Test**: `renderTest (CommandTemplate repl testTemplate testArguments
  targetPlaceholder) memoryLimit testTarget`, once per test target per test
  run — `memoryLimitFlag` (computed from `test_memory_limit` exactly as
  `mkTestCommand` did before this split) is folded into `arguments` inside
  `renderTest` itself, not computed by the caller.
- **Eval**: `renderEval (CommandTemplate repl evalTemplate evalArguments
  targetPlaceholder) [Bare moduleName]`, once per source file being
  evaluated.

---

## Backward Compatibility Mapping

| Deprecated key | Behavior when set |
|---|---|
| `command` | Used as `build.command_template`'s template if `build.command_template` is unset. Never affects `test`/`eval` templates (matches today: `mkTestCommand`/`runFileEvals` never read `command.arguments`). |
| `targets` | Used as `build.targets`'s source if `build.targets` is unset. Also still the fallback source for deriving `test.targets` (via `projectTestTargets`) when neither `test.targets` nor `test_targets` is set — matches today's `resolveTestTargets`. |
| `test_targets` | Used as `test.targets`'s source if `test.targets` is unset. |

Precedence when both old and new keys are set: the new (`build`/`test`/`eval`
section) key wins; the deprecated key is ignored for resolution purposes but
still triggers the deprecation warning below.

### Deprecation warnings

`loadSession` logs one `Log.warn` per deprecated key that is present
(non-default) in the parsed config, regardless of whether it was overridden
by a new key:

```
"session.command is deprecated; use session.build.command_template instead."
"session.targets is deprecated; use session.build.targets instead."
"session.test_targets is deprecated; use session.test.targets instead."
```

### Removal timeline

`command`, `targets`, and `test_targets` are removed no earlier than the
release whose PVP `A.B` component is 3 major bumps past the version that
first ships the deprecation warning above. E.g. if the warning ships in
`0.5.0.0` (first `A.B` = `0.5`), the earliest removal is `0.8.0.0`. Until
removal, `Config`'s `FromJSON` instance keeps accepting the deprecated keys
and `loadSession` keeps applying the mapping table above unchanged.

---

## Consumer Changes

- `Tricorder.Daemon.Core` calls `Tricorder.Session.Command.renderTest`
  directly (`Tricorder.Daemon.TestRunner.mkTestCommand` is retired — its
  logic moved into `renderTest`; see "Template/rendered-command separation"
  below), producing a `TestCommand` immediately, against the one test
  target it's running.
- `Tricorder.Daemon.EvalCommentRunner.runFileEvals` calls
  `Tricorder.Session.Command.renderEval` instead of constructing
  `Command repl [] [...]` directly, rendering an `EvalCommand` immediately
  against the one module being evaluated.
- `Tricorder.Session.Command.resolveCommand` is split into `resolveRepl`
  (above) plus per-form resolution functions
  (`resolveBuildCommand`, `resolveTestCommand`, `resolveEvalCommand`)
  implementing the algorithm above, all consumed from `Tricorder.Session`
  (`loadSession`) and stored on `Session` (replacing the single
  `Session.command :: Command` field with `Session.build :: CommandTemplate`,
  `Session.buildTargets :: [Target]`, `Session.test :: CommandTemplate`,
  `Session.eval :: CommandTemplate` — see "Template/rendered-command
  separation" below).

### Template/rendered-command separation

`Command` (the type carrying `repl`, `template`, `arguments`, `targets`,
`placeholder` together) is replaced by four distinct types with no overlap:

- `CommandTemplate { repl, template, arguments, placeholder }` — an
  as-yet-unrendered command. Deliberately has **no** `targets` field: a
  template doesn't know what it will run against yet, and callers must
  supply that explicitly.
- `BuildCommand`, `TestCommand`, `EvalCommand` — each a
  `newtype X = X { getXCommand :: Text }` wrapping a fully rendered
  command, one per phase. Once rendered, nothing about `Repl`, the
  template, or the placeholder matters anymore — a rendered command is
  "just" a string — but keeping each phase's result in its own newtype
  (rather than collapsing all three to plain `Text`) stops a command
  rendered for one phase from being passed to another phase's plumbing by
  accident, and follows this codebase's existing
  `newtype Foo = Foo { getFoo :: X }` convention (`TestTimeout`,
  `WatchDirs`, `ReplBuildDir`, …).

Three functions bridge `CommandTemplate` to a rendered command — one per
phase, not one generic `render` — because the phases don't render
identically:

```haskell
renderBuild :: CommandTemplate -> [Target] -> BuildCommand
renderTest  :: CommandTemplate -> Maybe ByteSize -> TestTarget -> TestCommand
renderEval  :: CommandTemplate -> [Target] -> EvalCommand
```

`renderBuild` and `renderEval` are plain wraps around the shared
substitution logic. `renderTest` additionally takes the test's memory limit
and folds the Tricorder-managed RTS flag (`--repl-options`/`--ghc-options`
depending on `Repl`) into `CommandTemplate.arguments` before rendering —
this used to be computed by the caller (`TestRunner.mkTestCommand`) and
handed to a generic `render`; now `renderTest` is the one place test
rendering happens, so the memory-limit logic lives right next to the
substitution it's augmenting. In every case, `[Target]`
(or `Maybe ByteSize`/`TestTarget` for `renderTest`) is a parameter to the
render function, never a field callers have to remember to fill in (or
leave empty and patch later, as the previous design's `resolveTestCommand`/
`resolveEvalCommand` did with `targets = []`, overridden by
`TestRunner`/`EvalCommentRunner` per invocation).

Consequences for the process-spawning layer
(`Tricorder.Daemon.Builder.with`, `Tricorder.Daemon.GhciSession.withGhci`/
`withGhciWith`, `Tricorder.Daemon.GhciSession.GhciProcess.withGhciProcess`):
all three take a plain `Text`, not any of `BuildCommand`/`TestCommand`/
`EvalCommand`. They're genuinely phase-agnostic — none of them ever
inspected anything beyond the rendered string at process-spawn time — so
forcing them to pick one phase's newtype would be a false constraint. Each
call site unwraps its own phase's newtype via `getXCommand` immediately
before handing the string down to that shared plumbing. This also drops
`Tricorder.Daemon.GhciSession.GhciProcess`'s dependency on
`Tricorder.Session.Command` entirely — rendering is a `Session`-level
concern, and the process layer only ever needed the resulting string.

Consequences for `Session`: `resolveBuildCommand` returns
`(CommandTemplate, [Target])` rather than a `Command` with the target list
already baked in, since `build`'s target list is known at session-load time
(unlike `test`/`eval`, resolved per invocation). `Session` stores both
halves — `build :: CommandTemplate` and `buildTargets :: [Target]` — and
`Tricorder.Daemon.Core` renders them together
(`renderBuild session.build session.buildTargets`) at the one point it
needs the literal command: the call into `Builder.with`. `buildTargets` is
usually equal to `Session.targets` (the discovered/configured target
list), except when that's empty, in which case it's `all` plus the
discovered test targets — the same fallback `resolveBuildCommand` computed
inline before this split, just now returned as data instead of embedded in
a `Command` value.

`Tricorder.Daemon.TestRunner`'s own `TestCommand` (previously a
`newtype TestCommand = TestCommand Text` local to that module, produced by
`mkTestCommand`/`unsafeMkTestCommand`) is retired in favor of
`Tricorder.Session.Command.TestCommand` — `TestRunner`'s `RunTestSuite`
effect and `runTestSuite` now take the `Command`-module type directly,
unwrapped via `getTestCommand` at the point `withGhciProcess` is called.
