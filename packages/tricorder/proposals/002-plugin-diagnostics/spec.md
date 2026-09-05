# Spec: Plugin-Based Structured Diagnostics

## Status

Draft. Read `design.md` first for context and rationale.

> The existing `Message` type already carries file, location, severity, and text via
> `ghcid`'s `Load` API. This document covers adding `errorCode`, `hints`, and
> `relatedSpans` — fields that require native GHC API access and cannot be extracted
> from GHCi's text output.

---

## tricorder-plugin

### Cabal Stanza

```cabal
library tricorder-plugin
  exposed-modules: Tricorder.Plugin
  build-depends:
      base
    , ghc      >= 9.8
    , aeson
    , network
    , unix
    , text
  ghc-options: -Wall
```

### Plugin Entry Point

```haskell
module Tricorder.Plugin (plugin) where

plugin :: Plugin
plugin = defaultPlugin
  { driverPlugin          = tricorderDriverPlugin
  , typeCheckResultAction = \_ _ env -> pure env  -- no-op in prototype
  , pluginRecompile       = purePlugin
  }

tricorderDriverPlugin :: [CommandLineOption] -> HscEnv -> IO HscEnv
tricorderDriverPlugin _opts env = do
  mPath <- lookupEnv "TRICORDER_PLUGIN_SOCKET"
  case mPath of
    Nothing   -> pure env   -- running outside daemon; do nothing
    Just path -> do
      h <- connectToSocket path
      pure (wrapLogger h env)
```

### Logger Wrapping

Key GHC API: `GHC.Utils.Logger.pushLogHook`, `GHC.Utils.Logger.putLogHook`.
Reference implementation in HLS: `ghcide/src/Development/IDE/GHC/Warnings.hs`.

```haskell
wrapLogger :: Handle -> HscEnv -> HscEnv
wrapLogger h env =
  let hook = logActionCompat $ \logFlags mReason mSev srcSpan msg ->
        hPutStrLn h . encode $ toDiagnosticEvent (hsc_dflags env) mReason mSev srcSpan msg
  in putLogHook (pushLogHook (const hook) (hsc_logger env)) env

-- GHC 9.8+: ResolvedDiagnosticReason wraps DiagnosticReason. No CPP needed.
logActionCompat
  :: (LogFlags -> Maybe DiagnosticReason -> Maybe Severity -> SrcSpan -> SDoc -> IO ())
  -> LogAction
logActionCompat f logFlags (MCDiagnostic sev (ResolvedDiagnosticReason wr) _) loc msg =
  f logFlags (Just wr) (Just sev) loc msg
logActionCompat f logFlags _ loc msg =
  f logFlags Nothing Nothing loc msg
```

`toDiagnosticEvent` extracts structured fields from the GHC types:

- **Error code**: `diagnosticCode` on `DiagnosticMessage` → `GHC.Types.Error`
- **Hints**: `diagnosticHints` on `DiagnosticMessage` → `[GhcHint]`, rendered to text
- **Related spans**: `diagnosticMessage`'s `errMsgContext` / note spans
- **Source location**: `SrcSpan` → start/end line and column

### Wire Protocol

All messages are newline-delimited JSON over the Unix socket (plugin → daemon).

```haskell
data PluginMessage
  = PDiagnostic DiagnosticEvent
  deriving (Generic, ToJSON, FromJSON)

data DiagnosticEvent = DiagnosticEvent
  { severity     :: Text              -- "error" | "warning"
  , file         :: Text
  , startLine    :: Int
  , startCol     :: Int
  , endLine      :: Int
  , endCol       :: Int
  , message      :: Text
  , errorCode    :: Maybe Text        -- e.g. "GHC-83865"
  , hints        :: [Text]
  , relatedSpans :: [RelatedSpan]
  } deriving (Generic, ToJSON, FromJSON)

data RelatedSpan = RelatedSpan
  { file      :: Text
  , startLine :: Int
  , startCol  :: Int
  , endLine   :: Int
  , endCol    :: Int
  , message   :: Text
  } deriving (Generic, ToJSON, FromJSON)
```

Example `DiagnosticEvent` on the wire:

```json
{
  "severity": "error",
  "file": "src/Foo.hs",
  "startLine": 12, "startCol": 4,
  "endLine": 12,   "endCol": 9,
  "message": "Variable not in scope: frobnicate",
  "errorCode": "GHC-83865",
  "hints": ["Perhaps you meant 'frobnize' (imported from Bar)"],
  "relatedSpans": [
    {
      "file": "src/Bar.hs",
      "startLine": 3, "startCol": 1,
      "endLine": 3,   "endCol": 10,
      "message": "defined here"
    }
  ]
}
```

---

## tricorder Daemon

### Socket Paths

```
$XDG_RUNTIME_DIR/tricorder/<hash>.sock          -- client-facing (unchanged)
$XDG_RUNTIME_DIR/tricorder/<hash>-plugin.sock   -- plugin-facing (new)
```

Both `<hash>` values are derived from the canonical project root path, same as the
existing client socket.

### Updated Message Type

```haskell
data Message = Message
  { severity     :: Severity
  , file         :: Text
  , startLine    :: Int
  , startCol     :: Int
  , endLine      :: Int
  , endCol       :: Int
  , title        :: Text
  , text         :: Text
  , errorCode    :: Maybe Text        -- Nothing in fallback mode
  , hints        :: [Text]            -- [] in fallback mode
  , relatedSpans :: [RelatedSpan]     -- [] in fallback mode
  } deriving (Generic, ToJSON, FromJSON)

data RelatedSpan = RelatedSpan
  { file      :: Text
  , startLine :: Int
  , startCol  :: Int
  , endLine   :: Int
  , endCol    :: Int
  , message   :: Text
  } deriving (Generic, ToJSON, FromJSON)
```

### GhciSession Interpreter: Startup Sequence

```
1. Compute plugin socket path (<hash>-plugin.sock)
2. Open Unix socket server at that path
3. Set TRICORDER_PLUGIN_SOCKET=<path> in subprocess environment
4. Spawn GHCi (cabal repl / configured command)
5. Race:
     a. Accept connection on plugin socket  → plugin mode
     b. Timeout (5 seconds)               → fallback mode
6. Log which mode is active
```

### GhciSession Interpreter: Reload Sequence

**Plugin mode:**
```
1. Clear accumulated DiagnosticEvents
2. Write `:reload\n` to GHCi stdin
3. Concurrently:
     a. Read DiagnosticEvent JSON lines from plugin socket → accumulate
     b. Read GHCi stdout lines → watch for /^(Ok|Failed), [0-9]+ modules? loaded\./
4. On stdout match: stop accumulating, assemble BuildResult from DiagnosticEvents
5. Update BuildStore
```

**Fallback mode:**
```
Delegate to existing ghcid-backed path unchanged.
Message.errorCode = Nothing, hints = [], relatedSpans = []
```

### Stdout Pattern (Plugin Mode)

The only GHCi stdout parsing retained in plugin mode:

```
/^Ok, [0-9]+ modules? loaded\./
/^Failed, [0-9]+ modules? loaded\./
```

This is used solely to detect build completion. Diagnostic content comes entirely
from the plugin socket.

---

## Future: Per-Module Events

When `typeCheckResultAction` is activated, the plugin emits an additional message
type per module:

```haskell
data PluginMessage
  = PDiagnostic DiagnosticEvent
  | PModuleDone ModuleDoneEvent    -- added in future iteration

data ModuleDoneEvent = ModuleDoneEvent
  { moduleName :: Text             -- e.g. "Foo.Bar"
  , file       :: Text             -- e.g. "src/Foo/Bar.hs"
  } deriving (Generic, ToJSON, FromJSON)
```

`TcGblEnv` (available in `typeCheckResultAction`) provides:
- `tcg_mod` — the current module name
- `tcg_mod_graph` — the full module graph for the session

With the module graph, the daemon knows the total module count for the current
compilation cycle and can detect completion without stdout parsing.
