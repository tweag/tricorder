module Tricorder.API.IfDaemonIsStopped
    ( IfDaemonIsStopped (..)
    , toArgs
    , doNothingFlagName
    )
where


data IfDaemonIsStopped
    = StartDaemon
    | DoNothing
    deriving stock (Eq)


toArgs :: IfDaemonIsStopped -> [String]
toArgs = \case
    StartDaemon -> []
    DoNothing -> ["--" <> doNothingFlagName]


doNothingFlagName :: String
doNothingFlagName = "prevent-daemon"
