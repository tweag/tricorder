module Tricorder.UI.Route
    ( Route (..)
    , name
    ) where


data Route
    = Main
    | Help
    | DaemonInfo
    | Tests
    | Evals
    deriving stock (Bounded, Enum, Eq)


name :: Route -> Text
name = \case
    Main -> "Dashboard"
    Help -> "Help"
    DaemonInfo -> "Daemon info"
    Tests -> "Tests"
    Evals -> "Eval comments"
