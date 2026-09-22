module Tricorder.CLI.Command.IfDaemonIsStopped
    ( IfDaemonIsStopped (..)
    , toArgs
    , startDaemonFlagName
    )
where


data IfDaemonIsStopped
    = StartDaemon
    | Fail


toArgs :: IfDaemonIsStopped -> [String]
toArgs = \case
    StartDaemon -> ["--" <> startDaemonFlagName]
    Fail -> []


startDaemonFlagName :: String
startDaemonFlagName = "start-daemon"
