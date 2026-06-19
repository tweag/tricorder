-- a fixture module: every binding is on show for the spec
{-# OPTIONS_GHC -Wno-missing-export-lists #-}

-- | A tracing usage of the observation framework: a server handling several requests
-- through one oblivious worker, where each request is its own trace.
--
-- The headline is obliviousness. The worker ('Serve') knows nothing of regions,
-- observations, or trace identity — it just turns a payload into a result. The spec bolts
-- the observation on from outside with a 'Atelier.Observe.Tap', filing each request under
-- one region and under the trace named by the request id it carried.
module ServerExample where

import Effectful (Dispatch (Dynamic), DispatchOf, Effect)
import Effectful.Dispatch.Dynamic (interpret, send)

import Data.Text qualified as Text


-- The worker's one effect: serve a request. It carries the request id (think: a trace
-- header) and the payload. A leaf — its interpreter does the "work" and stays oblivious
-- to every observation wrapped around it.
data Serve :: Effect where
    Serve :: Int -> Text -> Serve m Int -- request id, payload; result: token count


type instance DispatchOf Serve = Dynamic


serve :: (Serve :> es) => Int -> Text -> Eff es Int
serve rid payload = send (Serve rid payload)


-- The base interpreter: the actual work, oblivious to observation.
runServe :: Eff (Serve : es) a -> Eff es a
runServe = interpret \_ -> \case
    Serve _ payload -> pure (length (Text.words payload))


-- A little workload: three requests, two of them sharing request id 1.
requests :: [(Int, Text)]
requests = [(1, "the quick brown fox"), (2, "lorem ipsum"), (1, "the lazy dog")]


-- The program is oblivious: it just handles each request. The instruments live outside.
workload :: (Serve :> es) => Eff es ()
workload = mapM_ (\(rid, p) -> void (serve rid p)) requests
