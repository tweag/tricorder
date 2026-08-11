[Tricorder 0.2.0.0](https://hackage.haskell.org/package/tricorder-0.2.0.0) is
out, bringing you "eval comments", a nicer `tricorder source`, a "restart"
keybind and some nice fixes for those of you with a single-package repo.

Drop a simple `-- $> 2 + 2` anywhere in your source code, and Tricorder will
evaluate it for you and show
you the output in `tricorder ui` and `tricorder eval-comments`.

Other notable changes:

- Better source lookup with `tricorder source`.
- Ability to restart the daemon from the TUI.
- `tricorder log --print-path` prints the full log path.
- Fix for `<no location info>` in certain single-package repos.
- Fix for excessive resource usage when `cabal` fails on startup.

The full change log is available at [Tricorder's repo][changelog].

[changelog]: https://github.com/tweag/tricorder/blob/main/tricorder/CHANGELOG.md#0200---2026-08-06
