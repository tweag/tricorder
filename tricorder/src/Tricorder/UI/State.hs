module Tricorder.UI.State
    ( Viewports (..)
    , State (..)
    , Processed (..)
    , TestFilter (..)
    , init
    , currentRoute
    , viewToViewport
    , cycleTestFilter
    , navigate
    ) where

import Atelier.Effects.Clock (Clock, TimeZone)
import Prelude hiding (init)

import Atelier.Effects.Clock qualified as Clock

import Tricorder.BuildState (Status (..))
import Tricorder.UI.Route (Route)

import Tricorder.UI.Route qualified as Route


data Viewports
    = MainViewport
    | DiagnosticViewport
    | TestViewport
    deriving stock (Eq, Ord, Show)


data State = State
    { status :: Processed Text Status
    , timeZone :: TimeZone
    , route :: Route
    , testFilter :: TestFilter
    }


data TestFilter = TestFilterAll | TestFilterFailedOnly
    deriving stock (Bounded, Enum, Eq)


cycleTestFilter :: TestFilter -> TestFilter
cycleTestFilter x = if x == maxBound then minBound else succ x


data Processed e a
    = Waiting
    | Failure e
    | Success a


currentRoute :: State -> Route
currentRoute = (.route)


viewToViewport :: Route -> Maybe Viewports
viewToViewport = \case
    Route.Tests -> Just TestViewport
    Route.Main -> Just DiagnosticViewport
    _ -> Nothing


navigate :: Route -> State -> State
navigate route s = s {route}


init :: (Clock :> es) => Eff es State
init = do
    tz <- Clock.currentTimeZone
    pure
        State
            { status = Waiting
            , timeZone = tz
            , route = Route.Main
            , testFilter = minBound
            }
