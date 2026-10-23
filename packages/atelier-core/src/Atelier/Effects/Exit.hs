-- | An effect for terminating the program with an exit code.
module Atelier.Effects.Exit
    ( -- * Effect
      Exit
    , with
    , success
    , failure

      -- * Interpreters
    , runIO
    , runNoOp
    )
where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_, reinterpret_)
import Effectful.Error.Static (runErrorNoCallStack, throwError)
import Effectful.TH (makeEffect)
import System.Exit (ExitCode (..))

import System.Exit qualified as IO


-- | Effect for terminating the program with an exit code.
data Exit :: Effect where
    -- | Terminate the program with the given 'ExitCode'. Does not return.
    With :: ExitCode -> Exit m a


makeEffect ''Exit


-- | Exit the program successfully (exit code 0).
success :: (Exit :> es) => Eff es a
success = with ExitSuccess


-- | Exit the program with a generic failure (exit code 1).
failure :: (Exit :> es) => Eff es a
failure = with (ExitFailure 1)


-- | Interpret 'Exit' by actually terminating the process.
runIO :: (IOE :> es) => Eff (Exit : es) a -> Eff es a
runIO = interpret_ \(With code) -> liftIO (IO.exitWith code)


-- | Exit interpreter that captures exit calls instead of terminating the process.
-- Returns 'Left' the exit code if the action exited, 'Right' the result otherwise.
runNoOp :: Eff (Exit : es) a -> Eff es (Either ExitCode a)
runNoOp =
    reinterpret_ (runErrorNoCallStack @ExitCode) \(With code) -> throwError code
