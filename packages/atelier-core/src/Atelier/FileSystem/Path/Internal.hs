{-# OPTIONS_HADDOCK hide #-}

-- |
-- Module      : Atelier.FileSystem.Path.Internal
-- Description : Internal types and functions to the "Atelier.FileSystem"
--               family of modules.
-- Copyright   : (c) <Tweag> 2026
-- License     : MIT
-- Maintainer  : <victor.bakke@tweag.io>
--
-- Internal types and functions for the "Atelier.FileSystem" family of modules.
-- The API of this module is considered unstable, and will not be reflected in
-- the change log or the package version of this package.
module Atelier.FileSystem.Path.Internal
    ( Absolute (..)
    , filePathToAbsolute
    , unsafeMapAbsolute
    , Relative (..)
    , filePathToRelative
    , unsafeMapRelative
    , SafePath (..)
    , UnsafePath (..)
    , Any (..)
    )
where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics
    ( Generically (..)
    )
import Prelude hiding (Any (..))

import System.FilePath qualified as Path
import Text.Read qualified as T


-- | A fully qualified, absolute path. Always starts with @\/@.
newtype Absolute = UnsafeMkAbsolute {unsafeGetAbsolute :: FilePath}
    deriving stock (Eq, Ord, Show)
    deriving (FromJSON, ToJSON, ToText) via FilePath


filePathToAbsolute :: FilePath -> Either Text Absolute
filePathToAbsolute path
    | Path.isAbsolute path = Right $ UnsafeMkAbsolute $ path
    | otherwise = Left "passed path is not absolute"


instance T.Read Absolute where
    readPrec = do
        firstChar <- T.get
        case firstChar of
            '/' -> do
                rest <- T.readPrec
                let path = '/' : rest
                if Path.isValid path
                    then pure $ UnsafeMkAbsolute path
                    else fail "Not a valid absolute path"
            _ -> fail "not an absolute path"


unsafeMapAbsolute :: (FilePath -> FilePath) -> Absolute -> Absolute
unsafeMapAbsolute f (UnsafeMkAbsolute path) = UnsafeMkAbsolute (f path)


-- | A relative path on the file system. Never starts with @\/@.
newtype Relative = UnsafeMkRelative {unsafeGetRelative :: FilePath}
    deriving stock (Eq, Ord, Show)
    deriving (FromJSON, ToJSON, ToText) via FilePath


filePathToRelative :: FilePath -> Either Text Relative
filePathToRelative path
    | Path.isRelative path = Right $ UnsafeMkRelative path
    | otherwise = Left "passed path is not relative"


instance T.Read Relative where
    readPrec = do
        firstChar <- T.get
        case firstChar of
            '/' -> fail "not a relative path"
            x -> do
                rest <- T.readPrec
                let path = x : rest
                if Path.isValid path
                    then pure $ UnsafeMkRelative path
                    else fail "Not a valid relative path"


unsafeMapRelative :: (FilePath -> FilePath) -> Relative -> Relative
unsafeMapRelative f (UnsafeMkRelative path) = UnsafeMkRelative (f path)


-- | Convenience class for constructing and destructing 'Absolute' and
-- 'Relative' paths for use with 'SafePath'.
class UnsafePath path where
    unsafeToPath :: FilePath -> path
    unsafeFromPath :: path -> FilePath
    unsafeMapPath :: (FilePath -> FilePath) -> path -> path
    safeToPath :: FilePath -> Either Text path


instance UnsafePath Absolute where
    unsafeToPath = UnsafeMkAbsolute
    unsafeFromPath = unsafeGetAbsolute
    unsafeMapPath = unsafeMapAbsolute
    safeToPath path
        | Path.isAbsolute path = Right $ UnsafeMkAbsolute $ path
        | otherwise = Left "passed path is not absolute"


instance UnsafePath Relative where
    unsafeToPath = UnsafeMkRelative
    unsafeFromPath = unsafeGetRelative
    unsafeMapPath = unsafeMapRelative
    safeToPath path
        | Path.isRelative path = Right $ UnsafeMkRelative path
        | otherwise = Left "passed path is not relative"


-- | Convenience wrapper to create simple instances for 'Absolute' and
-- 'Relative'. For internal use.
newtype SafePath path = SafePath {getSafePath :: path}
    deriving stock (Functor)


-- | Can hold any sort of 'Path' value. Useful for heterogenous lists.
data Any
    = Absolute Absolute
    | Relative Relative
    deriving stock (Eq, Generic, Ord, Show)
    deriving (FromJSON, ToJSON) via Generically Any


instance ToText Any where
    toText (Absolute p) = toText p
    toText (Relative p) = toText p


instance UnsafePath Any where
    unsafeToPath f
        | "/" `isPrefixOf` f = Absolute $ UnsafeMkAbsolute f
        | otherwise = Relative $ UnsafeMkRelative f
    unsafeFromPath (Absolute p) = unsafeFromPath p
    unsafeFromPath (Relative p) = unsafeFromPath p
    unsafeMapPath f (Absolute p) = Absolute $ unsafeMapAbsolute f p
    unsafeMapPath f (Relative p) = Relative $ unsafeMapRelative f p
    safeToPath path
        | Path.isAbsolute path = Absolute <$> filePathToAbsolute path
        | otherwise = Relative <$> filePathToRelative path
