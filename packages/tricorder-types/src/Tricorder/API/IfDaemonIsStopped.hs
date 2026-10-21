module Tricorder.API.IfDaemonIsStopped
    ( IfDaemonIsStopped (..)
    , toArgs
    , startDaemonFlagName
    )
where


data IfDaemonIsStopped
    = StartDaemon
    | DoNothing
    deriving stock (Eq)


toArgs :: IfDaemonIsStopped -> [String]
toArgs = \case
    StartDaemon -> ["--" <> startDaemonFlagName]
    DoNothing -> []


startDaemonFlagName :: String
startDaemonFlagName = "start-daemon"
