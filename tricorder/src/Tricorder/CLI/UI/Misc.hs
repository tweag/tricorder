module Tricorder.CLI.UI.Misc
    ( err
    , warn
    , ok
    , emphasis
    , subtle
    , hBoxSpaced
    , vBoxSpaced
    ) where

import Brick
    ( Padding (..)
    , Widget
    , attrName
    , hBox
    , padLeft
    , padTop
    , vBox
    , withDefAttr
    )


err :: Widget n -> Widget n
err = withDefAttr $ attrName "error"


warn :: Widget n -> Widget n
warn = withDefAttr $ attrName "warning"


ok :: Widget n -> Widget n
ok = withDefAttr $ attrName "ok"


emphasis :: Widget n -> Widget n
emphasis = withDefAttr $ attrName "emphasis"


subtle :: Widget n -> Widget n
subtle = withDefAttr $ attrName "subtle"


hBoxSpaced :: Int -> [Widget n] -> Widget n
hBoxSpaced _ [] = hBox []
hBoxSpaced pad (x : xs) = hBox $ x : (padLeft (Pad pad) <$> xs)


vBoxSpaced :: Int -> [Widget n] -> Widget n
vBoxSpaced _ [] = vBox []
vBoxSpaced pad (x : xs) = vBox $ x : (padTop (Pad pad) <$> xs)
