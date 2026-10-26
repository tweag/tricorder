module Atelier.Effects.Arguments.Switch (parser) where

import Options.Applicative (FlagFields, Parser, flag', internal, long, style)
import Options.Applicative.Builder.Internal (FlagFields (..), Mod (..))
import Options.Applicative.Types (OptName (..))

import Data.List qualified as List
import Options.Applicative.Help qualified as Doc


-- | Builder for a switch that has an inverse option as well in the form of
-- `--no-<flag-name>`. Automatically finds the long name and short name among
-- the options passed. If no long name is set, then `--no-<flag-name>` will not
-- be made available, and this parser behaves just like the regular `switch`
-- parser builder from `optparse-applicative`. The flags may be repeated, and
-- the last one given wins.
parser
    :: Mod FlagFields Bool
    -- ^ Extra flag options to use.
    -> Parser Bool
parser opts =
    fmap (maybe False last . nonEmpty)
        $ many
        $ maybe empty inactiveParser longName
            <|> activeParser shortName longName opts
  where
    Mod f _ _ = opts
    realOpts = f $ FlagFields [] False
    shortName =
        viaNonEmpty head
            $ mapMaybe
                ( \case
                    OptShort c -> Just c
                    _ -> Nothing
                )
                realOpts.flagNames
    longName =
        viaNonEmpty head
            $ mapMaybe
                ( \case
                    OptLong l -> Just l
                    _ -> Nothing
                )
                realOpts.flagNames


activeParser :: Maybe Char -> Maybe String -> Mod FlagFields Bool -> Parser Bool
activeParser shortName longName opts =
    flag' True $ opts <> style (const displayName)
  where
    displayName = mconcat $ Doc.punctuate "," $ displayedShortName <> displayedLongName
    displayedShortName = maybe [] (one . Doc.pretty . ("-" <>) . List.singleton) shortName
    displayedLongName = maybe [] (one . Doc.pretty . ("--[no-]" <>)) longName


inactiveParser :: String -> Parser Bool
inactiveParser longName =
    flag' False $ long ("no-" <> longName) <> internal
