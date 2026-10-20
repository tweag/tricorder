module Tricorder.API.Force
    ( Force (..)
    , toArgs
    , forceFlagName
    )
where


data Force = Force | NoForce


toArgs :: Force -> [String]
toArgs Force = ["--" <> forceFlagName]
toArgs NoForce = []


forceFlagName :: String
forceFlagName = "force"
