-- | An effect for generating UUIDs.
--
-- 'runGenUUID' produces fresh random (version 4) UUIDs; 'runGenUUIDConst'
-- returns a fixed UUID every time, for deterministic tests. The 'UUID' type is
-- re-exported from @uuid@.
module Atelier.Effects.UUID
    ( GenUUID
    , UUID
    , gen
    , runGenUUID
    , runGenUUIDConst
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
runGenUUID :: (IOE :> es) => Eff (GenUUID : es) a -> Eff es a
runGenUUID = interpret_ \Gen -> liftIO nextRandom


-- | Interpret 'GenUUID' so 'gen' always returns the given fixed UUID, for tests.
runGenUUIDConst :: UUID -> Eff (GenUUID : es) a -> Eff es a
runGenUUIDConst uuid = interpret_ \Gen -> pure uuid
