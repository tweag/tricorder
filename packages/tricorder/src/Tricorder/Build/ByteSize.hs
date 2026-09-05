module Tricorder.Build.ByteSize
    ( ByteSize (..)
    , Unit (..)
    , asBytes
    , toRTSSize
    , fromText
    )
where

import Text.Megaparsec (Parsec, eof, parseMaybe)
import Text.Megaparsec.Char (space, string')
import Text.Megaparsec.Char.Lexer (decimal)
import Prelude hiding (toText)

import Text.Show qualified as S


data ByteSize = ByteSize {amount :: Integer, unit :: Unit}
    deriving stock (Eq, Generic, Ord)


instance Show ByteSize where
    show ByteSize {amount, unit} = show amount <> show unit


data Unit
    = B
    | KB
    | KiB
    | MB
    | MiB
    | GB
    | GiB
    | TB
    | TiB
    | PB
    | PiB
    deriving stock (Eq, Generic, Ord, Show)


asBytes :: ByteSize -> Integer
asBytes bs = bs.amount * multiplier bs.unit


multiplier :: Unit -> Integer
multiplier = \case
    B -> 1
    KB -> 1000
    KiB -> 1024
    MB -> 1000 `pow` 2
    MiB -> 1024 `pow` 2
    GB -> 1000 `pow` 3
    GiB -> 1024 `pow` 3
    TB -> 1000 `pow` 4
    TiB -> 1024 `pow` 4
    PB -> 1000 `pow` 5
    PiB -> 1024 `pow` 5
  where
    pow :: Integer -> Integer -> Integer
    pow = (^)


toRTSSize :: ByteSize -> Text
toRTSSize bs = show $ bs.amount * multiplier bs.unit


fromText :: Text -> Maybe ByteSize
fromText = parseMaybe byteSizeP


byteSizeP :: Parser ByteSize
byteSizeP = do
    amount <- decimal
    space
    unit <- unitP
    pure $ ByteSize {amount, unit}


unitP :: Parser Unit
unitP =
    asum
        [ string' "kb" *> pure KB
        , string' "kib" *> pure KiB
        , string' "mb" *> pure MB
        , string' "mib" *> pure MiB
        , string' "gb" *> pure GB
        , string' "gib" *> pure GiB
        , string' "tb" *> pure TB
        , string' "tib" *> pure TiB
        , string' "pb" *> pure PB
        , string' "pib" *> pure PiB
        , string' "b" *> pure B
        , eof *> pure B
        ]


type Parser = Parsec Void Text
