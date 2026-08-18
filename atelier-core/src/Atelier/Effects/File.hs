{-# OPTIONS_GHC -Wno-redundant-constraints #-}

-- | A handle-based file IO effect.
--
-- A thin 'Eff' wrapper over the handle operations in "System.IO" and
-- "Data.Text.IO" ('withFile', 'hPutText', 'hGetLine', …), so file IO passes
-- through the effect system instead of raw 'IO'. 'Handle' and 'BufferMode' are
-- re-exported for convenience.
module Atelier.Effects.File
    ( File
    , Handle
    , BufferMode (..)
    , IOMode (..)
    , withFile
    , hClose
    , hFlush
    , hGetLine
    , hPutText
    , hPutTextLn
    , hPutLBs
    , hPutLBsLn
    , hIsEOF
    , hSetBuffering
    , runFile
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
data File :: Effect


type instance DispatchOf File = Static WithSideEffects


data instance StaticRep File = File


-- | Lifted `System.IO.withFile`:
withFile :: (File :> es, HasCallStack) => FilePath -> IOMode -> (Handle -> Eff es a) -> Eff es a
withFile fp m f = unsafeSeqUnliftIO \unlift -> IO.withFile fp m (unlift . f)


-- | Lifted `System.IO.hClose`.
hClose :: (File :> es, HasCallStack) => Handle -> Eff es ()
hClose = unsafeEff_ . IO.hClose


-- | Lifted `System.IO.hFlush`.
hFlush :: (File :> es, HasCallStack) => Handle -> Eff es ()
hFlush = unsafeEff_ . IO.hFlush


-- | Lifted `System.IO.hGetLine`.
hGetLine :: (File :> es, HasCallStack) => Handle -> Eff es Text
hGetLine = unsafeEff_ . fmap toText . IO.hGetLine


-- | Lifted `Data.Text.IO.hPutStr`. Encodes via the handle's text encoding,
-- symmetric with `hGetLine`.
hPutText :: (File :> es, HasCallStack) => Handle -> Text -> Eff es ()
hPutText h = unsafeEff_ . TIO.hPutStr h


-- | `hPutText` with a `\n` at the end.
hPutTextLn :: (File :> es, HasCallStack) => Handle -> Text -> Eff es ()
hPutTextLn h = unsafeEff_ . TIO.hPutStrLn h


-- | Lifted `System.IO.hIsEOF`.
hIsEOF :: (File :> es, HasCallStack) => Handle -> Eff es Bool
hIsEOF = unsafeEff_ . IO.hIsEOF


-- | Lifted `Data.ByteString.Lazy.Char8.hPutStr`.
hPutLBs :: (File :> es, HasCallStack) => Handle -> LByteString -> Eff es ()
hPutLBs h s = unsafeEff_ $ LB8.hPutStr h s


-- | Lifted `System.IO.hSetBuffering`.
hSetBuffering :: (File :> es, HasCallStack) => Handle -> BufferMode -> Eff es ()
hSetBuffering h m = unsafeEff_ $ IO.hSetBuffering h m


-- | `hPutLBs` with a `\n` at the end.
hPutLBsLn :: (File :> es, HasCallStack) => Handle -> LByteString -> Eff es ()
hPutLBsLn h = hPutLBs h . (<> "\n")


-- | Run file operations.
runFile :: (HasCallStack, IOE :> es) => Eff (File : es) a -> Eff es a
runFile = evalStaticRep File
