{-# LANGUAGE UndecidableInstances #-}

module Tricorder.CLI.App.CLIResponse (CLIResponse (..)) where

import Data.Aeson (ToJSON)
import Data.Aeson.Text (encodeToLazyText)


-- | This is effectively `Text.Show`, but for printing to the terminal.
class CLIResponse a where
    -- | Render the value in such a way that it displays nicely on a terminal.
    renderCLIResponse :: a -> LText


instance (ToJSON a) => CLIResponse a where
    renderCLIResponse = encodeToLazyText
