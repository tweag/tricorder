module Tricorder.API.IfBuildIsPending
    ( IfBuildIsPending (..)
    , toArgs
    , waitForBuildFlagName
    )
where


data IfBuildIsPending
    = ShowCurrent
    | WaitForBuild
    deriving stock (Eq)


toArgs :: IfBuildIsPending -> [String]
toArgs WaitForBuild = ["--" <> waitForBuildFlagName]
toArgs ShowCurrent = []


waitForBuildFlagName :: String
waitForBuildFlagName = "wait"
