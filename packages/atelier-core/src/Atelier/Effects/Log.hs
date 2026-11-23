-- | Log effect with hierarchical namespace support.
--
-- Provides structured logging with composable namespaces for better organization.
--
-- == Basic Usage
--
-- @
-- myComponent :: (Log :> es) => Eff es ()
-- myComponent = do
--     info "Starting component"
--     -- Logs: [INFO] [MyModule.myComponent#42] Starting component
-- @
--
-- == Using Namespaces
--
-- @
-- processData :: (Log :> es) => Eff es ()
-- processData = withNamespace "processor" $ do
--     info "Processing started"
--     -- Logs: [INFO] [processor] [MyModule.processData#10] Processing started
--
--     withNamespace "validation" $ do
--         info "Validating input"
--         -- Logs: [INFO] [processor.validation] [MyModule.processData#13] Validating input
-- @
module Atelier.Effects.Log
    ( -- * Effect
      Log
    , Message (..)
    , log
    , info
    , warn
    , debug
    , err
    , withNamespace

      -- * Interpreters
    , runIO
    , runNoOp
    , runToHandle
    , runWriter
    )
where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (localSeqUnlift, reinterpret, reinterpretWith)
import Effectful.Reader.Static (Reader, ask, local, runReader)
import Effectful.TH (makeEffect)
import Effectful.Writer.Static.Shared (Writer, tell)
import System.IO (Handle, hFlush, stdout)

import Data.ByteString.Char8 qualified as B8
import Effectful.Reader.Static qualified as Reader

import Atelier.Effects.Log.Severity (Severity)

import Atelier.Effects.Log.Severity qualified as Severity


-- | Effect for structured logging with hierarchical namespaces.
data Log :: Effect where
    -- | Emit a fully-formed log 'Message'.
    LogMsg :: Message -> Log m ()
    -- | Run an action with an extra namespace segment appended to the current
    -- one.
    WithNamespace :: Namespace -> m a -> Log m a
    -- | Get the namespace in effect for the current action.
    GetNamespace :: Log m Namespace


-- | A single log record.
data Message = Message
    { namespace :: Namespace
    -- ^ The hierarchical namespace the message was logged under.
    , text :: Text
    -- ^ The human-readable message body.
    , severity :: Severity
    -- ^ The severity level of the message.
    , stack :: CallStack
    -- ^ The call site, captured via 'HasCallStack'.
    }


newtype Namespace = Namespace Text
    deriving stock (Eq, Show)
    deriving newtype (IsString)


instance Semigroup Namespace where
    Namespace "" <> Namespace b = Namespace b
    Namespace a <> Namespace "" = Namespace a
    Namespace a <> Namespace b = Namespace (a <> "." <> b)


makeEffect ''Log


-- | Log a message at the given severity, capturing the current namespace and
-- call site.
log :: (HasCallStack, Log :> es) => Severity -> Text -> Eff es ()
log severity text = do
    namespace <- getNamespace
    withFrozenCallStack
        $ logMsg
            Message
                { stack = callStack
                , namespace
                , severity
                , text
                }


-- | Log a message at 'DEBUG' severity.
debug :: (HasCallStack, Log :> es) => Text -> Eff es ()
debug = withFrozenCallStack $ log Severity.DEBUG


-- | Log a message at 'INFO' severity.
info :: (HasCallStack, Log :> es) => Text -> Eff es ()
info = withFrozenCallStack $ log Severity.INFO


-- | Log a message at 'WARN' severity.
warn :: (HasCallStack, Log :> es) => Text -> Eff es ()
warn = withFrozenCallStack $ log Severity.WARN


-- | Log a message at 'ERROR' severity.
err :: (HasCallStack, Log :> es) => Text -> Eff es ()
err = withFrozenCallStack $ log Severity.ERROR


-- | Consumes `Log` effects, and discards the logged messages
runNoOp :: Eff (Log : es) a -> Eff es a
runNoOp = reinterpret (runReader (Namespace "")) $ \env -> \case
    LogMsg _ -> pure ()
    WithNamespace ns act -> localSeqUnlift env $ \unlift ->
        local (<> ns) $ unlift act
    GetNamespace -> ask


-- | Interpret 'Log' by writing formatted messages to stdout.
--
-- The minimum severity defaults to 'Config'\'s @minimumSeverity@, but can be
-- overridden at runtime by the @DEBUG@, @LOGGING@ or @LOG@ environment
-- variables (checked in that order).
runIO :: (IOE :> es, Reader Severity.Config :> es) => Eff (Log : es) a -> Eff es a
runIO action = do
    Severity.Config severity <- Reader.ask

    reinterpretWith (runReader (Namespace "")) action \lenv -> \case
        LogMsg msg ->
            liftIO $ when (msg.severity >= severity) do
                -- NOTE: We use hPutStr here with an appended newline because
                -- hPutStrLn is not atomic for ByteStrings longer than 1024 bytes.
                -- Data.Text.IO.hPutStrLn is not atomic for even short Texts.
                B8.hPutStr stdout
                    . encodeUtf8
                    . (<> "\n")
                    . formatMessage
                    $ msg
                hFlush stdout
        WithNamespace ns act -> localSeqUnlift lenv $ \unlift ->
            local (<> ns) $ unlift act
        GetNamespace -> ask


-- | Like 'runLog' but writes to the given 'Handle' instead of stdout.
-- Useful for daemons that want to write logs to a file.
runToHandle :: (IOE :> es) => Handle -> Severity -> Eff (Log : es) a -> Eff es a
runToHandle handle minSeverity action =
    reinterpretWith (runReader (Namespace "")) action \env -> \case
        LogMsg msg ->
            liftIO $ when (msg.severity >= minSeverity) do
                B8.hPutStr handle . encodeUtf8 . (<> "\n") . formatMessage $ msg
                hFlush handle
        WithNamespace ns act -> localSeqUnlift env $ \unlift ->
            local (<> ns) $ unlift act
        GetNamespace -> ask


-- | Interpret 'Log' by collecting messages into a 'Writer', for tests.
runWriter :: (Writer [Message] :> es) => Eff (Log : es) a -> Eff es a
runWriter = reinterpret (runReader (Namespace "")) $ \env -> \case
    LogMsg msg -> tell [msg]
    WithNamespace ns act -> localSeqUnlift env $ \unlift ->
        local (<> ns) $ unlift act
    GetNamespace -> ask


formatMessage :: Message -> Text
formatMessage msg =
    mconcat
        [ square $ show msg.severity
        , " "
        , showNamespace msg.namespace
        , msg.text
        ]
  where
    showNamespace (Namespace "") = ""
    showNamespace (Namespace ns) = square ns <> " "


square :: Text -> Text
square s = "[" <> s <> "]"
