module Tricorder.CLI.App.Output
    ( Output (..)
    , TextOutput (..)
    , JsonOutput (..)
    )
where

import Data.Aeson (ToJSON)
import Data.Aeson.Text (encodeToLazyText)
import System.Exit (ExitCode)

import Tricorder.CLI.App.CLIResponse (CLIResponse (..))


data Output a
    = Fail ExitCode LText
    | Output a


instance Functor Output where
    fmap f = \case
        Fail exitCode reason -> Fail exitCode reason
        Output val -> Output $ f val


instance Applicative Output where
    pure = Output
    Fail exitCode reason <*> _ = Fail exitCode reason
    _ <*> Fail exitCode reason = Fail exitCode reason
    Output f <*> Output a = Output $ f a


instance Monad Output where
    Fail exitCode reason >>= _ = Fail exitCode reason
    Output a >>= f = f a


instance (CLIResponse a) => CLIResponse (Output a) where
    renderCLIResponse = \case
        Fail _ reason -> "Error: " <> reason
        Output val -> renderCLIResponse val


-- | Textual output to the terminal.
data TextOutput a = TextOutput a


instance (CLIResponse a) => CLIResponse (TextOutput a) where
    renderCLIResponse (TextOutput val) = renderCLIResponse val


-- | JSON output to the terminal.
data JsonOutput a = JsonOutput a


instance (ToJSON a) => CLIResponse (JsonOutput a) where
    renderCLIResponse (JsonOutput val) = encodeToLazyText val
