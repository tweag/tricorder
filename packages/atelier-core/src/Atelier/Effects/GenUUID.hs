-- | An effect for generating UUIDs.
module Atelier.Effects.GenUUID
    ( GenUUID
    , UUID
    , gen
    , runIO
    , runConst
    )
where

import Data.UUID (UUID)
import Data.UUID.V4 (nextRandom)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)


-- | Effect for generating UUIDs.
data GenUUID :: Effect where
    -- | Generate a UUID.
    Gen :: GenUUID m UUID


makeEffect ''GenUUID


-- | Interpret 'GenUUID' by generating fresh random (version 4) UUIDs.
--
-- Produces fresh random (version 4) UUIDs.
runIO :: (IOE :> es) => Eff (GenUUID : es) a -> Eff es a
runIO = interpret_ \Gen -> liftIO nextRandom


-- | Interpret 'GenUUID' so 'gen' always returns the given fixed UUID, for tests.
--
-- Returns a fixed UUID every time, for deterministic tests.
runConst :: UUID -> Eff (GenUUID : es) a -> Eff es a
runConst uuid = interpret_ \Gen -> pure uuid
