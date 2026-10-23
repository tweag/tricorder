{-# OPTIONS_GHC -Wno-redundant-constraints #-}

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
    , runIO
    )
where

import Effectful (Dispatch (..), DispatchOf, Effect, IOE)
import Effectful.Dispatch.Static (SideEffects (..), StaticRep, evalStaticRep, unsafeEff_)
import Options.Applicative (ParserInfo)

import Options.Applicative qualified as Opt


-- | Reading and parsing command-line arguments.
data Arguments :: Effect


type instance DispatchOf Arguments = Static WithSideEffects


data instance StaticRep Arguments = Arguments


-- \| Read @argv@ and parse it with the given parser, printing usage and
-- exiting on failure (see @optparse-applicative@'s 'Opt.execParser').
execParser :: (Arguments :> es) => ParserInfo a -> Eff es a
execParser = unsafeEff_ . Opt.execParser


runIO :: (IOE :> es) => Eff (Arguments : es) a -> Eff es a
runIO = evalStaticRep Arguments
