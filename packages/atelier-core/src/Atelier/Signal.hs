-- | Termination handler based on Cabal's `Distribution.Client.Signal`.
-- See https://github.com/haskell/cabal/blob/aeb7dbfabad38289cb36da6fdf78acee99b69e3b/cabal-install/src/Distribution/Client/Signal.hs
module Atelier.Signal (installTerminationHandler) where

import Effectful (IOE, withSeqEffToIO)
import Effectful.Concurrent (Concurrent, myThreadId, throwTo)
import Effectful.Exception (asyncExceptionFromException, asyncExceptionToException)
import System.Posix.Signals (Handler (..), installHandler, sigTERM)
import Text.Show (Show (..))


-- | Terminated is an asynchronous exception, thrown when
-- SIGTERM is received. It's to 'kill' what 'UserInterrupt'
-- is to Ctrl-C.
data Terminated = Terminated


instance Exception Terminated where
    toException = asyncExceptionToException
    fromException = asyncExceptionFromException


instance Show Terminated where
    show Terminated = "terminated"


installTerminationHandler :: (Concurrent :> es, IOE :> es) => Eff es ()
installTerminationHandler = do
    mainThreadId <- myThreadId
    void
        $ withSeqEffToIO \unlift ->
            installHandler
                sigTERM
                (CatchOnce $ unlift $ throwTo mainThreadId Terminated)
                Nothing
