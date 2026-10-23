module Atelier.Types.JSON.Renamed (Renamed) where

import Data.Aeson (FromJSON (..), ToJSON (..))
import GHC.TypeLits (KnownSymbol, Symbol, symbolVal)


data Renamed (from :: Symbol) (to :: Symbol)
    deriving stock (Eq, Generic, Show)


instance ToJSON (Renamed from to) where
    toJSON = \case {}
    toEncoding = \case {}


instance forall from to. (KnownSymbol from, KnownSymbol to) => FromJSON (Renamed from to) where
    parseJSON _ =
        fail
            $ "The property '"
                <> symbolVal (Proxy @from)
                <> "' has been renamed or moved to '"
                <> symbolVal (Proxy @to)
                <> "'"
