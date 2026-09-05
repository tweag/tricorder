module Tricorder.SourceLookup.SourceQuery
    ( SourceQuery (..)
    , ModuleName (..)
    , parseSourceQuery
    , renderSourceQuery
    )
where

import Data.Aeson (FromJSON, ToJSON)

import Data.Text qualified as T


-- | A query for module source: optionally scoped to a single top-level symbol.
data SourceQuery = SourceQuery
    { moduleName :: ModuleName
    , function :: Maybe Text
    -- ^ The symbol to slice: 'Nothing' is the whole module; @'Just' name@ is a
    -- single top-level declaration — a value binding, or (by initial casing) a
    -- type, class, or constructor.
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, Hashable, ToJSON)


-- | Parse the CLI/MCP query syntax @MODULE[#FUNCTION]@ into a 'SourceQuery'.
parseSourceQuery :: Text -> SourceQuery
parseSourceQuery t =
    let (m, rest) = T.break (== '#') t
    in  SourceQuery
            { moduleName = ModuleName m
            , function = if T.null rest then Nothing else Just (T.tail rest)
            }


-- | Render a 'SourceQuery' back to its @MODULE[#FUNCTION]@ argument form, the
-- inverse of 'parseSourceQuery'.
renderSourceQuery :: SourceQuery -> String
renderSourceQuery (SourceQuery {moduleName, function}) =
    toString (unModuleName moduleName) <> maybe "" (\f -> "#" <> toString f) function


-- | A dotted Haskell module name, e.g. @"Data.Map.Strict"@.
newtype ModuleName = ModuleName {unModuleName :: Text}
    deriving newtype (Eq, FromJSON, Hashable, IsString, Ord, Show, ToJSON)
