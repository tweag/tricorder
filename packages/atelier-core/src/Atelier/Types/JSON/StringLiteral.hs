module Atelier.Types.JSON.StringLiteral (StringLiteral (..)) where

import Data.Aeson (FromJSON (..), ToJSON (..), withText)
import Data.Default (Default (..))
import GHC.TypeLits (KnownSymbol, Symbol, symbolVal)


-- | Parses and encodes to a specific string literal.
--
-- For parsing, if the parsed JSON value matches the specified string literal,
-- the 'Default' value of the type is returned. All other JSON values are
-- considered invalid.
--
-- This is useful for types consisting of a single nullary constructor that you
-- want to encode as a specific string (that is different from the 'Show' and
-- 'Read' instances of the constructor.)
newtype StringLiteral (literal :: Symbol) a = StringLiteral {getStringLiteral :: a}


instance forall lit a. (Default a, KnownSymbol lit) => FromJSON (StringLiteral lit a) where
    parseJSON = withText "StringLiteral" \t ->
        if t == toText (symbolVal (Proxy :: Proxy lit))
            then pure $ StringLiteral def
            else fail $ "unexpected value of string. expected " <> symbolVal (Proxy :: Proxy lit)


instance forall lit a. (KnownSymbol lit) => ToJSON (StringLiteral lit a) where
    toJSON _ = toJSON $ symbolVal (Proxy :: Proxy lit)
    toEncoding _ = toEncoding $ symbolVal (Proxy :: Proxy lit)
