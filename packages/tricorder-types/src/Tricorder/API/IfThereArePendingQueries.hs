module Tricorder.API.IfThereArePendingQueries
    ( IfThereArePendingQueries (..)
    , toArgs
    , dontWaitFlagName
    )
where


data IfThereArePendingQueries = Wait | DontWait


toArgs :: IfThereArePendingQueries -> [String]
toArgs DontWait = ["--" <> dontWaitFlagName]
toArgs Wait = []


dontWaitFlagName :: String
dontWaitFlagName = "ignore-pending-queries"
