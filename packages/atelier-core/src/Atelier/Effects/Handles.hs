{-# OPTIONS_GHC -Wno-redundant-constraints #-}

module Atelier.Effects.Handles
    ( Handles
    , Handle
    , BufferMode (..)
    , IOMode (..)
    , with
    , hClose
    , hFlush
    , hGetLine
    , hPutText
    , hPutTextLn
    , hPutLBs
    , hPutLBsLn
    , hIsEOF
    , hSetBuffering
    , run
    )
where

import Effectful (Dispatch (..), DispatchOf, Effect, IOE)
import Effectful.Dispatch.Static
    ( SideEffects (..)
    , StaticRep
    , evalStaticRep
    , unsafeEff_
    , unsafeSeqUnliftIO
    )
import System.IO (BufferMode (..), Handle)
import Prelude

import Data.ByteString.Lazy.Char8 qualified as LB8
import Data.Text.IO qualified as TIO
import System.IO qualified as IO


-- | Operations concerning file handles.
data Handles :: Effect


type instance DispatchOf Handles = Static WithSideEffects


data instance StaticRep Handles = Handles


-- | Lifted `System.IO.withFile`:
with :: (Handles :> es, HasCallStack) => FilePath -> IOMode -> (Handle -> Eff es a) -> Eff es a
with fp m f = unsafeSeqUnliftIO \unlift -> IO.withFile fp m (unlift . f)


-- | Lifted `System.IO.hClose`.
hClose :: (Handles :> es, HasCallStack) => Handle -> Eff es ()
hClose = unsafeEff_ . IO.hClose


-- | Lifted `System.IO.hFlush`.
hFlush :: (Handles :> es, HasCallStack) => Handle -> Eff es ()
hFlush = unsafeEff_ . IO.hFlush


-- | Lifted `System.IO.hGetLine`.
hGetLine :: (Handles :> es, HasCallStack) => Handle -> Eff es Text
hGetLine = unsafeEff_ . fmap toText . IO.hGetLine


-- | Lifted `Data.Text.IO.hPutStr`. Encodes via the handle's text encoding,
-- symmetric with `hGetLine`.
hPutText :: (Handles :> es, HasCallStack) => Handle -> Text -> Eff es ()
hPutText h = unsafeEff_ . TIO.hPutStr h


-- | `hPutText` with a `\n` at the end.
hPutTextLn :: (Handles :> es, HasCallStack) => Handle -> Text -> Eff es ()
hPutTextLn h = unsafeEff_ . TIO.hPutStrLn h


-- | Lifted `System.IO.hIsEOF`.
hIsEOF :: (Handles :> es, HasCallStack) => Handle -> Eff es Bool
hIsEOF = unsafeEff_ . IO.hIsEOF


-- | Lifted `Data.ByteString.Lazy.Char8.hPutStr`.
hPutLBs :: (Handles :> es, HasCallStack) => Handle -> LByteString -> Eff es ()
hPutLBs h s = unsafeEff_ $ LB8.hPutStr h s


-- | Lifted `System.IO.hSetBuffering`.
hSetBuffering :: (Handles :> es, HasCallStack) => Handle -> BufferMode -> Eff es ()
hSetBuffering h m = unsafeEff_ $ IO.hSetBuffering h m


-- | `hPutLBs` with a `\n` at the end.
hPutLBsLn :: (Handles :> es, HasCallStack) => Handle -> LByteString -> Eff es ()
hPutLBsLn h = hPutLBs h . (<> "\n")


-- | Run file operations.
run :: (HasCallStack, IOE :> es) => Eff (Handles : es) a -> Eff es a
run = evalStaticRep Handles
