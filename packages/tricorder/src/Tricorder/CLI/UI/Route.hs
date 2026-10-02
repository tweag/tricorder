module Tricorder.CLI.UI.Route
    ( Route (..)
    , name
    )
where


data Route
    = Main
    | Tests
    | Evals
    deriving stock (Bounded, Enum, Eq)


name :: Route -> Text
name = \case
    Main -> "Dashboard"
    Tests -> "Tests"
    Evals -> "Eval comments"
