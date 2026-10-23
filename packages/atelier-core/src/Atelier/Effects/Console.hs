-- | An effect for writing bytes and text to an output stream.
--
-- The single primitive is 'putStr' (raw bytes); 'putStrLn', 'putText' and
-- 'putTextLn' build on it. 'runConsole' writes to stdout, 'runConsoleHandle' to
-- any 'Handle', and 'runConsoleToList' captures output for tests.
module Atelier.Effects.Console
    ( -- * Effect
      Console
    , Output (..)
    , putStrLn
    , putStr
    , putTextLn
    , putText

      -- * Interpreters
    , runHandle
    , runIO
    , runToList
    , runOut
    )
where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_, reinterpret_)
import Effectful.State.Static.Shared (modify, runState)
import Effectful.TH (makeEffect)
import System.IO (Handle, stderr, stdout)
import Prelude

import Data.ByteString.Char8 qualified as B8


-- | Effect for writing output to a stream.
data Console :: Effect where
    -- | Write raw bytes to the output.
    PutStr :: ByteString -> Console m ()


data Output = Stdout | Stderr


makeEffect ''Console


-- | Write a 'ByteString' followed by a newline.
putStrLn :: (Console :> es) => ByteString -> Eff es ()
putStrLn = putStr . (<> "\n")


-- | Write 'Text', encoded as UTF-8 bytes.
putText :: (Console :> es) => Text -> Eff es ()
putText = putStr . encodeUtf8


-- | Write 'Text' as UTF-8 bytes, followed by a newline.
putTextLn :: (Console :> es) => Text -> Eff es ()
putTextLn = putStrLn . encodeUtf8


-- | Interpret 'Console' by writing to the given 'Handle'.
runHandle :: (IOE :> es) => Handle -> Eff (Console : es) a -> Eff es a
runHandle h = interpret_ \case
    PutStr s -> liftIO $ B8.hPut h s


-- | Interpret 'Console' by writing to 'stdout'.
runIO :: (IOE :> es) => Eff (Console : es) a -> Eff es a
runIO = runHandle stdout


-- | Interpret 'Console' by collecting all writes into a list, in order. Useful
-- for asserting on output in tests.
runToList :: Eff (Console : es) a -> Eff es (a, [ByteString])
runToList = reinterpret_ (fmap (second reverse) . runState []) \case
    PutStr s -> modify (s :)


runOut :: (IOE :> es) => Output -> Eff (Console : es) a -> Eff es a
runOut = \case
    Stderr -> runHandle stderr
    Stdout -> runHandle stdout
