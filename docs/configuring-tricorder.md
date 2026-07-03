# Configuring Tricorder

Tricorder is designed to work for most codebases and users out-of-the-box
without any extra configuration. Despite this, sometimes there is a need to
change the behavior of Tricorder for a given repo.

Tricorder uses the same configuration file for both the daemon running the
build in the background as well as the CLI used to interact with the daemon:
`.tricorder.yaml` in your repository of choice.

## Daemon configuration

The Tricorder daemon is configured using the following options under the
`session` map in `.tricorder.yaml`:

```yaml
session:
  command: cabal repl --enable-multi-repl
  targets: [lib:foo, exe:bar]
  watch_dirs: [foo/src]
  test_targets: [test:foo]
  repl_build_dir: /tmp
  test_timeout: 10
  turbo_tests: false
```

- `command`: Build command to use to enter the cabal repl. If not specified,
  Tricorder will attempt to check whether `stack` is used, and also whether it
  is running in a multi-package repository. Specify this option if you think
  Tricorder is incorrect in the command it picks.
- `targets`: Build components to compile in the `cabal repl`. If not specified,
  Tricorder will build all components detected in the `.cabal` file for the
  repository.
- `watch_dirs`: Directories to watch. When a file is changed in a watched
  directory, Tricorder will attempt to rebuild all targets. If not specified,
  Tricorder will add all `hs-source-dirs` for the configured or detected
  targets as `watch_dirs`.
- `watch_exclusion_patterns`: POSIX-compliant regular expressions to match
  files you do _not_ want to watch in `watch_dirs`. Tricorder will always
  ignore files in `dist-newstyle`. Defaults to no patterns, meaning all files
  (except those in `dist-newstyle`) will be watched.
- `test_targets`: Targets to treat as test suites. If not specified, all
  targets in `targets` starting with `test:` are treated as `test_targets`.
  Specify `test_targets: []` to disable running tests with Tricorder.
- `repl_build_dir`: Directory to keep compiled files from the repl. Defaults to
  `dist-newstyle/tricorder` in the repository.
- `test_timeout`: Number of seconds each test target is granted before it is
  considered "timed out". Defaults to `10` seconds. Set to `0` to disable the
  timeout.
- `turbo_tests`: Keep a long-lived `cabal repl` session per test suite and drive
  it with `:reload` + `:main` on each run, instead of spawning a fresh process
  every time. Repeated runs are much faster because they skip `cabal repl`
  startup and only recompile what changed. Sessions are respawned automatically
  when they would otherwise go stale: `:reload` rebuilds a suite's own modules,
  and an edit to anything *outside* the suite's own `hs-source-dirs` (a
  dependency package, a `.cabal` file) evicts the session so the next run
  rebuilds against the change. Defaults to `false`.

## CLI configuration

The CLI can be configured through some options in `.tricorder.yaml`, but is
mostly configured through the commandline itself. See `tricorder --help` for
information on commandline options you can pass to Tricorder.

### Custom Key Bindings

You can specify custom key bindings for `tricorder ui`'s TUI in your
`.tricorder.yaml` file.

The format is as follows:

```yaml
keybindings:
  <event>: <keybind>[, <keybind>, <keybind>, ...]
```

`keybindings` is an object whose keys are event names and whose values are
strings of key bindings, each key binding in the string separated by a comma.

The following event names are recognized
(keep this list in sync with the `KeyEvent` type in
`tricorder/src/Tricorder/UI/Keys.hs` [ref:keybinding_events]):

- `toggle_daemon_info_view`: Toggle displaying the daemon info tab.
- `toggle_help`: Toggle displaying the help tab. This tab shows available key
  bindings, including your custom key bindings.
- `cycle_test_view`: Toggle the tests tab and cycle through test results views.
  Cycle past the end to go back to the dashboard.
- `toggle_eval_comments`: Toggle displaying eval comments that have been
  evaluated.
- `restart_daemon`: Restart the background daemon — stops it if running, then
  starts a fresh instance. Bound to `R` by default.
- `exit_view`: Exit the current view, going back to the dashboard. If you are
  at the dashboard already, this exits the TUI.
- `scroll_up`: Scroll up in the diagnostic list.
- `scroll_down`: Scroll down in the diagnostic list.
- `quit`: Exit the TUI.

Key binds are specified in the format `<modifiers>-<key>`, where `<modifiers>`
is an optional `-`-separated list of modifier keys, and `<key>` is any
non-modifier key on your keyboard.

Alternatively, the key bind can be `unbound`, which removes default key
bindings for the given event.

The following modifiers are recognized:

- `s`, `shift`
- `m`, `meta`
- `a`, `alt`
- `c`, `ctrl`, `control`

The following non-modifier keys are recognized:

- `f1`, `f2`, ...
- `esc`
- `backspace`
- `enter`
- `left`
- `right`
- `up`
- `down`
- `upleft`
- `upright`
- `downleft`
- `downright`
- `center`
- `backtab`
- `printscreen`
- `pause`
- `insert`
- `home`
- `pgup`
- `del`
- `end`
- `pgdown`
- `begin`
- `menu`
- `space`
- `tab`
- All letter, symbol and number keys.

#### Example

```yaml
keybindings:
  quit: c-q
  scroll_up: k, up
  scroll_down: j, down
  toggle_daemon_info_view: unbound
```
