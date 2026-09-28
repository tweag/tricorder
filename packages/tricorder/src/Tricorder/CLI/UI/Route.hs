module Tricorder.CLI.UI.Route
    ( Route (..)
    , name
    )
where


data Route
    = Main
    | Help
    | Tests
    | Evals
    deriving stock (Bounded, Enum, Eq)


name :: Route -> Text
name = \case
    Main -> "Dashboard"
    Help -> "Help"
    Tests -> "Tests"
    Evals -> "Eval comments"
