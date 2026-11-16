module Tricorder.Runtime.ProjectHash
    ( ProjectHash (..)
    , asReader
    )
where

import Data.Aeson (FromJSON, ToJSON)
import Effectful.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader)
import Numeric (showHex)

import Atelier.FileSystem.Path qualified as Path
import Atelier.FileSystem.Path.Internal qualified as Path.Internal
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))


newtype ProjectHash = ProjectHash
    { getProjectHash :: Path.Relative
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Path.Relative


asReader
    :: (FileSystem :> es, Reader ProjectRoot :> es)
    => Eff (Reader ProjectHash : es) a -> Eff es a
asReader act = do
    ProjectRoot projectRoot <- Reader.ask
    canonProjectRoot <- Path.canonicalize projectRoot
    let hash = Path.Internal.UnsafeMkRelative $ hashPath $ Path.toFilePath canonProjectRoot
    Reader.runReader (ProjectHash hash) act


-- | Polynomial hash of a file path, returned as a hex string.
hashPath :: FilePath -> String
hashPath path =
    let n = foldl' (\acc c -> acc * 31 + toInteger (ord c)) (0 :: Integer) path
    in  showHex (abs n `mod` (16 ^ (16 :: Integer))) ""
