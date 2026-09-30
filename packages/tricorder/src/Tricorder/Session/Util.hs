module Tricorder.Session.Util
    ( showList
    , indent
    )
where

import Data.Text qualified as T


showList :: (a -> Text) -> [a] -> Text
showList f xs
    | null xs = "<empty list>"
    | otherwise = T.intercalate "\n" $ (("- " <>) . f) <$> xs


indent :: Text -> Text
indent = T.unlines . fmap ("  " <>) . T.lines
