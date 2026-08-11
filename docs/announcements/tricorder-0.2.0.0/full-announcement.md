# Tricorder v0.2.0.0

[Tricorder 0.2.0.0](https://hackage.haskell.org/package/tricorder-0.2.0.0) is
out, bringing you "eval comments", a nicer `tricorder source`, a "restart"
keybind and some nice fixes for those of you with a single-package repo.

The full change log is available at [Tricorder's repo][changelog].

## Eval comments

![terminal window with Tricorder showing 2 + 2 as an eval comment][eval-comment-simple]

Drop an expression into a specially-marked comment anywhere in a module, and
Tricorder will evaluate it against that module's top-level bindings every
time the build succeeds — showing you the result right there, without
opening `cabal repl` or copy-pasting code into GHCi.

There are three ways to write one.

**Single-line**, for quick checks:

```haskell
-- $> 2 + 2
```

**Multi-line, in a line comment**, for expressions that don't fit on one
line:

```haskell
-- $$>
-- someFunc 12
-- >> someOtherFunc
-- <$$
```

**Block eval comment**, the same idea inside a `{- -}` block, which some
people find more ergonomic to write:

```haskell
{- $$>
someFunc 12
>> someOtherFunc
<$$ -}
```

All three forms are evaluated in the context of the module they live in, so
you can freely reference any top-level function or value defined there —
handy for sanity-checking a helper function or eyeballing a data structure
while you edit. Any expression which can be evaluated by GHCi can be used!

Results show up in two places:

- **In the TUI**, press `e` to open the eval comments view. Each comment is
  listed with its file, line number, the expression, and the evaluated result
  (or a "Running..." indicator while it's still evaluating).
- **On the command line**, run `tricorder eval-comments` to print all eval
  comments and their results for the current build. Add `--wait` to block until
  the in-progress build finishes, and/or `--json` for structured output.

See [Features of Tricorder – Eval Comments] for the full more information.

## Source lookup from source distribution tarballs

Previously, `tricorder source` would use `ghc-pkg` to pick out and parse the
Haddock HTML generated for whichever module you specified. This proved to be
problematic in two main ways:

1. Parsing HTML [can be tricky][parsing-html].
2. The HTML produced by Haddock is inconsistent between Cabal versions.

In Tricorder 0.2.0.0, `tricorder source` fetches the actual source code from
the source distribution tarball, and parses out the relevant parts from there
instead.

Tricorder utilizes cabal's global sdist cache, fetching packages as needed.
This means more accurate sources, and `tricorder source` even works for
packages that do not have any generated Haddock HTML.

## Other notable mentions

- **Restart the daemon from the TUI.** Press `R` (rebindable, like every
  other key in Tricorder) to restart the daemon without leaving the TUI. It
  reconnects automatically as soon as the new daemon is ready.
- **Print the full log path.** `tricorder log --print-path` prints the path to
  the current repo's Tricorder log file, so you can `tail -f` it or point
  another tool at it without hunting it down manually.
- **Fix for `<no location info>` in certain single-package repos**.
  Single-package repos no longer show an empty diagnostics list in certain
  cases. If you experienced that `cabal repl` showed compilation errors, but
  `tricorder ui` just showed `<no location info>`, this might do the trick for
  you.
- **Excessive resource usage when `cabal` fails on startup.** The build no
  longer gets stuck looping after a startup failure. For example, if you forgot
  to `nix develop` or `direnv allow` to bring `cabal` into your `PATH`,
  Tricorder's daemon would just loop infinitely as it attempted to use `cabal`,
  bloating its logs and eating at your processor time. But this is no more!

[changelog]: https://github.com/tweag/tricorder/blob/main/tricorder/CHANGELOG.md#0200---2026-08-06
[Features of Tricorder - Eval Comments]: https://github.com/tweag/tricorder/blob/main/docs/features-of-tricorder.md
[eval-comment-simple]: ./eval-comment-simple.png
[parsing-html]: https://stackoverflow.com/questions/1732348/regex-match-open-tags-except-xhtml-self-contained-tags
