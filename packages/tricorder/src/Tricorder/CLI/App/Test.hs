module Tricorder.CLI.App.Test (run) where

run :: Command -> Eff es ()
run = \case
  Suites filter -> 
