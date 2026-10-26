module Tricorder.API.IfBuildIsPending
    ( IfBuildIsPending (..)
    , toArgs
    , useCurrentFlagName
    , useCurrentShortFlagName
    )
where


data IfBuildIsPending
    = UseCurrent
    | WaitForBuild
    deriving stock (Eq)


toArgs :: IfBuildIsPending -> [String]
toArgs WaitForBuild = []
toArgs UseCurrent = ["--" <> useCurrentFlagName]


useCurrentFlagName :: String
useCurrentFlagName = "use-current"


useCurrentShortFlagName :: Char
useCurrentShortFlagName = 'c'
