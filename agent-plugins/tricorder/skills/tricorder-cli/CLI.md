### `tricorder --help`

```
tricorder — robust GHCi daemon with structured querying

Usage: tricorder COMMAND [--version]

  tricorder — daemon-based GHCi build status

Available options:
  --version                Show version and exit
  -h,--help                Show this help text

Available commands:
  ui                       Auto-refreshing terminal display.
  status                   Print build diagnostics (--json for machine-readable
                           output.)
  test                     See statuses and information on configured test
                           suites.
  source                   Print the Haskell source of one or more project or
                           installed modules.
  eval-comments            Show eval comments from the latest build.
  daemon                   Manage the daemon itself.
  log                      Show daemon log output.
```

### `tricorder ui --help`

```
Usage: tricorder ui 

  Auto-refreshing terminal display.

Available options:
  -h,--help                Show this help text
```

### `tricorder status --help`

```
Usage: tricorder status [-c,--[no-]use-current] [-j|--json] [-v|--verbose] 
                        [--expand N] [--[no-]prevent-daemon]

  Print build diagnostics (--json for machine-readable output.)

Available options:
  -c,--[no-]use-current    Skip waiting for the pending build and use the
                           current (potentially incomplete) build status.
  -j,--json                Output full build state as JSON
  -v,--verbose             Print full GHC message body under each diagnostic,
                           and full test suite error messages
  --expand N               Print full GHC message body for diagnostic #N
  --[no-]prevent-daemon    Normally, the daemon will be started if it is not
                           already running. This flag prevents that, and instead
                           will make Tricorder produce an error if the daemon is
                           not running.
  -h,--help                Show this help text
```

### `tricorder test --help`

```
Usage: tricorder test COMMAND

  See statuses and information on configured test suites.

Available options:
  -h,--help                Show this help text

Available commands:
  suites                   Show test suites, their test cases and output.
```

### `tricorder test suites --help`

```
Usage: tricorder test suites [TEST-TARGET...] [-f|--failed-only] 
                             [--fields FIELDS] [-j|--json] 
                             [-c,--[no-]use-current] [--[no-]prevent-daemon] 
                             [--help-json]

  Show test suites, their test cases and output.

Available options:
  TEST-TARGET...           Test suites to show (default: all)
  -f,--failed-only         Show only failed test suites, and only their failed
                           test cases.
  --fields FIELDS          Comma-separated list of fields to return for each test suite.

                           Available fields:
                               name
                               status
                               error
                               passed_cases
                               total_cases
                               duration_ms
                               output
                               cases(description, outcome, failure)

                           Select nested fields with parentheses,
                           e.g. --fields 'name,cases(description,failure)'.
                           A field without parentheses shows all of its nested fields.

                           Default fields:
                           name,status,error,passed_cases,total_cases,duration_ms

  -j,--json                Output full build state as JSON
  -c,--[no-]use-current    Skip waiting for the pending build and use the
                           current (potentially incomplete) build status.
  --[no-]prevent-daemon    Normally, the daemon will be started if it is not
                           already running. This flag prevents that, and instead
                           will make Tricorder produce an error if the daemon is
                           not running.
  --help-json              Show the JSON Schema of the output of --json and
                           exit.
  -h,--help                Show this help text

Available fields: name, status, error, passed_cases, total_cases, duration_ms,
output, cases(description, outcome, failure) Select nested fields with
parentheses, e.g. --fields 'name,cases(description,failure)'. A field without
parentheses shows all of its nested fields.
```

### `tricorder source --help`

```
Usage: tricorder source Module[#function] [--max-depth N] [--max-modules N]

  Print the Haskell source of one or more project or installed modules.

Available options:
  Module[#function]        Module or Module#function
  --max-depth N            Follow at most N re-export hops when a symbol is not
                           defined in the queried module (default: 5)
  --max-modules N          Read at most N modules while following re-exports
                           (default: 24)
  -h,--help                Show this help text
```

### `tricorder eval-comments --help`

```
Usage: tricorder eval-comments [-c,--[no-]use-current] [-j|--json] 
                               [--[no-]prevent-daemon]

  Show eval comments from the latest build.

Available options:
  -c,--[no-]use-current    Skip waiting for the pending build and use the
                           current (potentially incomplete) build status.
  -j,--json                Output full build state as JSON
  --[no-]prevent-daemon    Normally, the daemon will be started if it is not
                           already running. This flag prevents that, and instead
                           will make Tricorder produce an error if the daemon is
                           not running.
  -h,--help                Show this help text
```

### `tricorder daemon --help`

```
Usage: tricorder daemon COMMAND

  Manage the daemon itself.

Available options:
  -h,--help                Show this help text

Available commands:
  info                     Information about the daemon.
  start                    Start the daemon (no-op if already running.)
  stop                     Stop the daemon.
  restart                  Restart the daemon.
```

### `tricorder daemon info --help`

```
Usage: tricorder daemon info [-j|--json]

  Information about the daemon.

Available options:
  -j,--json                Output full build state as JSON
  -h,--help                Show this help text
```

### `tricorder daemon start --help`

```
Usage: tricorder daemon start 

  Start the daemon (no-op if already running.)

Available options:
  -h,--help                Show this help text
```

### `tricorder daemon stop --help`

```
Usage: tricorder daemon stop [--[no-]ignore-pending-queries]

  Stop the daemon.

Available options:
  --[no-]ignore-pending-queries
                           Do not wait for queries and clients with pending
                           requests.
  -h,--help                Show this help text
```

### `tricorder daemon restart --help`

```
Usage: tricorder daemon restart [--[no-]ignore-pending-queries]

  Restart the daemon.

Available options:
  --[no-]ignore-pending-queries
                           Do not wait for queries and clients with pending
                           requests.
  -h,--help                Show this help text
```

### `tricorder log --help`

```
Usage: tricorder log [--print-path]

  Show daemon log output.

Available options:
  --print-path             Print the path to the log file instead of its
                           contents
  -h,--help                Show this help text
```

