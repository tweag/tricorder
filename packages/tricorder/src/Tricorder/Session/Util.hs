module Tricorder.Session.Util
    ( displayList
    , indent
    )
where

import Data.Text qualified as T


displayList :: (a -> Text) -> [a] -> Text
displayList f xs
    | null xs = "<empty list>"
    | otherwise = T.intercalate "\n" $ (("- " <>) . f) <$> xs


indent :: Text -> Text
indent = T.unlines . fmap ("  " <>) . T.lines
