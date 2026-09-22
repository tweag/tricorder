module Tricorder.CLI.Command.WaitMode
    ( WaitMode (..)
    , toArgs
    )
where


data WaitMode
    = ShowCurrent
    | WaitForBuild
    deriving stock (Eq)


toArgs :: WaitMode -> [String]
toArgs WaitForBuild = ["--wait"]
toArgs ShowCurrent = []
