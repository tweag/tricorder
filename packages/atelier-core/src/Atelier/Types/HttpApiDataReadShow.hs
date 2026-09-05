-- | Derive 'FromHttpApiData' and 'ToHttpApiData' for a type from its 'Read' and
-- 'Show' instances.
--
-- Handy for values that appear in URL path segments or query strings and whose
-- textual form is exactly their 'Show' output, such as small enums:
--
-- @
-- data Mode = Fast | Slow
--     deriving stock (Read, Show)
--     deriving (FromHttpApiData, ToHttpApiData) via (HttpApiDataReadShow Mode)
-- @
--
-- The encoding is the bare 'Show' output, so @Fast@ travels on the wire as the
-- segment @\/mode\/Fast@ or the query parameter @?mode=Slow@, and is read back
-- with 'Read'. Values whose 'Show' output contains characters that need
-- percent-encoding (spaces, @\/@, @&@) are best avoided here.
module Atelier.Types.HttpApiDataReadShow (HttpApiDataReadShow (..)) where

import Web.HttpApiData (FromHttpApiData (..), ToHttpApiData (..))


-- | Carrier for deriving HTTP-API-data instances via 'Read' and 'Show'.
newtype HttpApiDataReadShow a
    = HttpApiDataReadShow {getHttpApiDataReadShow :: a}


instance (Read a) => FromHttpApiData (HttpApiDataReadShow a) where
    parseUrlPiece = bimap toText HttpApiDataReadShow . readEither . toString


instance (Show a) => ToHttpApiData (HttpApiDataReadShow a) where
    toUrlPiece = show . getHttpApiDataReadShow
