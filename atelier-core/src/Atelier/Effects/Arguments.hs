-- | Effect for parsing command-line arguments.
--
-- A thin wrapper over @optparse-applicative@'s 'Opt.execParser', so callers
-- read and parse @argv@ through the effect system rather than raw 'IO'.
module Atelier.Effects.Arguments
    ( -- * Effect
      Arguments

      -- * Re-exported from @optparse-applicative@
    , ParserInfo

      -- * Operations
    , execParser

      -- * Interpreters
    , runArgumentsIO
    )
where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)
import Options.Applicative (ParserInfo)

import Options.Applicative qualified as Opt


-- | Reading and parsing command-line arguments.
data Arguments :: Effect where
    -- | Read @argv@ and parse it with the given parser, printing usage and
    -- exiting on failure (see @optparse-applicative@'s 'Opt.execParser').
    ExecParser :: ParserInfo a -> Arguments m a


makeEffect ''Arguments


runArgumentsIO :: (IOE :> es) => Eff (Arguments : es) a -> Eff es a
runArgumentsIO = interpret_ \case
    ExecParser pinfo -> liftIO $ Opt.execParser pinfo
