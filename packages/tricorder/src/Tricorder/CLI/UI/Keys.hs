module Tricorder.CLI.UI.Keys
    ( KeyEvent (..)
    , Config
    , keys
    , mkDispatcher
    , viewKeybindings
    , mkKeyConfig
    )
where

import Atelier.Effects.Console (Console)
import Atelier.Effects.Exit (Exit, exitFailure)
import Brick
    ( EventM
    , Widget
    , halt
    , txt
    , vBox
    , vScrollBy
    , viewportScroll
    )
import Brick.Keybindings
    ( Binding
    , BindingState
    , EventTrigger (..)
    , Handler (..)
    , KeyConfig
    , KeyDispatcher
    , KeyEventHandler (..)
    , KeyEvents
    , KeyHandler (..)
    , ToBinding (..)
    , allActiveBindings
    , binding
    , ctrl
    , keyDispatcher
    , keyEvents
    , newKeyConfig
    , onEvent
    , parseBindingList
    )
import Brick.Keybindings.Pretty (ppBinding)
import Brick.Widgets.Core (hBox)
import Control.Monad.State (gets, modify)
import Data.Aeson (FromJSON (..))
import Data.Default (Default (..))
import Effectful.Reader.Static (Reader, ask)
import Graphics.Vty (Key (..))
import Text.Casing (quietSnake)

import Atelier.Effects.Console qualified as Console
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text qualified as T

import Tricorder.CLI.UI.Misc (warn)
import Tricorder.CLI.UI.State
    ( Processed (Waiting)
    , State (..)
    , Viewports (..)
    , currentRoute
    , cycleTestFilter
    , viewToViewport
    )

import Tricorder.CLI.UI.Route qualified as Route


-- | [tag:keybinding_events] The TUI key events. This type is the source of truth
-- for the event names documented in README.md under "Custom Key Bindings", which
-- points back here with a matching @ref@. Whenever you add, remove, or rename a
-- 'KeyEvent', update that list to match — @tagref check@ flags the dangling
-- reference if this tag is renamed or dropped without touching the docs.
data KeyEvent
    = SwitchTabPrev
    | SwitchTabNext
    | ToggleHelp
    | CycleTestView
    | RestartDaemon
    | ScrollUp
    | ScrollDown
    | Quit
    deriving stock (Bounded, Enum, Eq, Ord, Show)


keyEventToText :: KeyEvent -> Text
keyEventToText = toText . quietSnake . show


keyEventTextMap :: Map Text KeyEvent
keyEventTextMap = Map.fromList $ (\e -> (keyEventToText e, e)) <$> universe


textToKeyEvent :: Text -> Maybe KeyEvent
textToKeyEvent = (`Map.lookup` keyEventTextMap)


eventToDesc :: KeyEvent -> Text
eventToDesc = \case
    ToggleHelp -> "toggle help"
    SwitchTabNext -> "switch to next tab"
    SwitchTabPrev -> "switch to previous tab"
    CycleTestView -> "cycle test tab views"
    RestartDaemon -> "restart daemon"
    ScrollUp -> "scroll up"
    ScrollDown -> "scroll down"
    Quit -> "quit"


keys :: KeyEvents KeyEvent
keys = keyEvents $ (\e -> (eventToDesc e, e)) <$> universe


eventToBinding :: KeyEvent -> [Binding]
eventToBinding = \case
    ToggleHelp -> [bind '?']
    SwitchTabPrev -> [bind 'h', binding KLeft []]
    SwitchTabNext -> [bind 'l', binding KRight []]
    CycleTestView -> [bind 't']
    RestartDaemon -> [bind 'R']
    ScrollUp -> [binding KUp []]
    ScrollDown -> [binding KDown []]
    Quit -> [bind 'q', ctrl 'c', binding KEsc []]


defaultBindings :: [(KeyEvent, [Binding])]
defaultBindings = (\e -> (e, eventToBinding e)) <$> universe


mkKeyConfig :: (Console :> es, Exit :> es, Reader Config :> es) => Eff es (KeyConfig KeyEvent)
mkKeyConfig = do
    customBindings <- parseCustomBindings
    pure $ newKeyConfig keys defaultBindings customBindings


newtype Config = Config (Map Text Text)
    deriving stock (Generic)
    deriving newtype (FromJSON)


instance Default Config where
    def = Config mempty


parseCustomBindings
    :: ( Console :> es
       , Exit :> es
       , Reader Config :> es
       )
    => Eff es [(KeyEvent, BindingState)]
parseCustomBindings = do
    Config cfg <- ask
    let (errors, customBindings) = partitionEithers $ uncurry parseEntry <$> Map.toList cfg
    unless (null errors) do
        Console.putTextLn "Error(s) encountered when attempting to parse key bindings:"
        traverse_ (Console.putTextLn . toText) errors
        exitFailure
    pure customBindings


parseEntry :: Text -> Text -> Either Text (KeyEvent, BindingState)
parseEntry ev binds =
    (,) <$> parsedEvent <*> parsedBinds
  where
    parsedEvent = parseKeyEvent ev
    parsedBinds = first toText $ parseBindingList binds


parseKeyEvent :: Text -> Either Text KeyEvent
parseKeyEvent ev = maybeToRight ("Unrecognized key event: " <> ev) $ textToKeyEvent ev


eventToHandler :: IO () -> KeyEvent -> KeyEventHandler KeyEvent (EventM Viewports State)
eventToHandler requestRestart = \case
    ToggleHelp -> onEvent ToggleHelp "Toggle help" do
        modify \s -> s {showHelp = not s.showHelp}
    SwitchTabNext -> onEvent SwitchTabNext "Switch to next tab" do
        modify \s ->
            s
                { route =
                    if s.route == maxBound
                        then minBound
                        else succ s.route
                }
    SwitchTabPrev -> onEvent SwitchTabPrev "Switch to previous tab" do
        modify \s ->
            s
                { route =
                    if s.route == minBound
                        then maxBound
                        else pred s.route
                }
    CycleTestView -> onEvent CycleTestView "Cycle between test tab views" do
        modify \s ->
            if
                | s.route /= Route.Tests -> s
                | otherwise -> s {testFilter = cycleTestFilter s.testFilter}
    RestartDaemon -> onEvent RestartDaemon "Restart the daemon" do
        liftIO requestRestart
        modify \s -> s {buildState = Waiting}
    ScrollUp -> onEvent ScrollUp "Scroll up" do
        mvp <- gets (viewToViewport . currentRoute)
        case mvp of
            Just vp -> vScrollBy (viewportScroll vp) (-1)
            Nothing -> pure ()
    ScrollDown -> onEvent ScrollDown "Scroll down" do
        mvp <- gets (viewToViewport . currentRoute)
        case mvp of
            Just vp ->
                vScrollBy (viewportScroll vp) 1
            Nothing -> pure ()
    Quit -> onEvent Quit "Exit" do
        halt


-- | Build the key dispatcher. @requestRestart@ is run (in 'IO') when the restart
-- key is pressed; it hands the request off to the worker that owns the daemon
-- control effects, since brick's 'EventM' cannot run them directly.
mkDispatcher
    :: (Console :> es, Exit :> es)
    => IO ()
    -> KeyConfig KeyEvent
    -> Eff es (KeyDispatcher KeyEvent (EventM Viewports State))
mkDispatcher requestRestart cfg =
    case keyDispatcher cfg $ eventToHandler requestRestart <$> universe of
        Left collisions -> do
            Console.putTextLn
                $ T.intercalate "\n\n"
                $ "Your key bindings have collisions:"
                    : (uncurry showCollision <$> collisions)
            exitFailure
        Right dispatcher -> pure dispatcher
  where
    showCollision binding' handlers =
        T.intercalate "\n"
            $ ("Key binding: " <> ppBinding binding')
                : (showCollidingHandler <$> handlers)
    showCollidingHandler handler =
        "  " <> case handler.khHandler.kehEventTrigger of
            ByEvent ev -> toText $ quietSnake $ show ev
            ByKey k -> show k


viewKeybindings :: (Ord k, Show k) => KeyConfig k -> [KeyEventHandler k m] -> Widget n
viewKeybindings kc =
    vBox
        . fmap (uncurry (viewEventAndTriggers kc))
        . Map.toList
        . foldr groupByEventName Map.empty
  where
    groupByEventName ev = Map.insertWith (<>) ev.kehHandler.handlerDescription [ev.kehEventTrigger]


viewEventAndTriggers :: (Ord k, Show k) => KeyConfig k -> Text -> [EventTrigger k] -> Widget n
viewEventAndTriggers kc eventName triggers =
    hBox
        [ warn $ txt $ eventName <> ": "
        , txt $ showBindings $ mconcat $ getBindings <$> triggers
        ]
  where
    showBindings = T.intercalate ", " . fmap ppBinding . sort . toList
    getBindings = \case
        ByKey k -> Set.singleton k
        ByEvent e -> Set.fromList $ allActiveBindings kc e
