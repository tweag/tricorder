module Tricorder.CLI.Command.WaitMode
    ( WaitMode (..)
    , toArgs
    , waitForBuildFlagName
    )
where


data WaitMode
    = ShowCurrent
    | WaitForBuild
    deriving stock (Eq)


toArgs :: WaitMode -> [String]
toArgs WaitForBuild = ["--" <> waitForBuildFlagName]
toArgs ShowCurrent = []


waitForBuildFlagName :: String
waitForBuildFlagName = "wait"
