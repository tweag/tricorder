-- | The 'RunningProcess' constructor, for tests that fabricate a handle.
--
-- Constructing one directly bypasses 'Atelier.Effects.Process.withProcessGroup'
-- and its guarantee that the process heads its own group, so the group-signalling
-- operations may target the wrong group. Production code should not import this.
module Atelier.Effects.Process.Internal
    ( RunningProcess (..)
    )
where

import System.Process.Typed qualified as TP


-- | A process run in its own group by 'Atelier.Effects.Process.withProcessGroup'.
-- Parameterised by its stdin, stdout and stderr stream types.
newtype RunningProcess i o e = RunningProcess (TP.Process i o e)
