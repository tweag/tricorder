module Atelier.Effects.Reader (project) where

import Effectful.Reader.Static (Reader)

import Effectful.Reader.Static qualified as Reader


-- | Use the value from an existing 'Reader' effect to interpret another
-- 'Reader' effect.
project :: (Reader a :> es) => (a -> b) -> Eff (Reader b : es) x -> Eff es x
project f act = do
    b <- f <$> Reader.ask
    Reader.runReader b act
