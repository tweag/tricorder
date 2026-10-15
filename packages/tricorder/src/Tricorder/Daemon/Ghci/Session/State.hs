module Tricorder.Daemon.Ghci.Session.State (State (..)) where


data State = Idle Int | Busy Int
    deriving stock (Eq, Show)
