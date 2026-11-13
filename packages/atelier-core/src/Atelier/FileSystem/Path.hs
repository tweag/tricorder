{-# LANGUAGE UndecidableInstances #-}

-- |
-- Module      : Atelier.FileSystem.Path
-- Description : Context-aware paths to more easily distinguish absolute paths
--               from relative paths.
-- Copyright   : (c) <Tweag> 2026
-- License     : MIT
-- Maintainer  : <victor.bakke@tweag.io>
-- Portability : non-portable (requires POSIX)
--
-- Functions from "Effectful.FileSystem" tailored for use with
-- "Atelier.FileSystem.Path" paths.
--
-- As of this writing in 2026-11-06, @atelier-core@ only supports POSIX
-- systems, so we only include the POSIX examples from "System.FilePath".
-- This module also does not include or consider the Windows-specific
-- drive-related functions from `System.FilePath`. Some functions are
-- re-exported from 'System.FilePath', and thus mention Windows-specific
-- behavior.
--
-- >>> fromFilePath @Absolute "/foo"
-- Just (absolute @"/foo")
--
-- >>> fromFilePath @Absolute "foo"
-- Nothing
--
-- >>> fromFilePath @Relative "/foo"
-- Nothing
--
-- >>> fromFilePath @Relative "foo"
-- Just (relative @"foo")
--
-- >>> import Atelier.FileSystem.Path qualified as Path
-- >>> import Atelier.FileSystem.Path ((</>))
-- >>> Path.absolute @"/foo" </> Path.relative @"bar/baz"
-- Path.absolute @"/foo/bar/baz"
module Atelier.FileSystem.Path
    ( -- * Absolute paths
      Absolute

      -- ** Constructors
    , abs
    , absolute

      -- ** Converting to 'Relative'
    , makeRelativeToCurrentDirectory
    , makeRelative

      -- * Relative paths
    , Relative

      -- ** Constructors
    , rel
    , relative

      -- * Converting to 'Absolute'
    , makeAbsolute

      -- * Any path
    , Any (..)
    , mapAny
    , withAny

      -- * Conversions to/from 'FilePath'
    , toFilePath
    , fromFilePath

      -- * Checks
    , exists
    , isPrefixOf
    , isSuffixOf

      -- * Separator predicates
    , Reexports.FilePath
    , Reexports.extSeparator
    , Reexports.isExtSeparator
    , Reexports.isPathSeparator
    , Reexports.isSearchPathSeparator
    , Reexports.pathSeparator
    , Reexports.pathSeparators
    , Reexports.searchPathSeparator

      -- * \$PATH methods
    , Reexports.splitSearchPath
    , Reexports.getSearchPath

      -- * Filename/Directory functions
    , splitFileName
    , takeFileName
    , replaceFileName
    , dropFileName
    , takeBaseName
    , replaceBaseName
    , takeDirectory
    , replaceDirectory

      -- * File extension
    , splitExtension
    , takeExtension
    , replaceExtension
    , (-<.>)
    , dropExtension
    , addExtension
    , hasExtension
    , (<.>)
    , splitExtensions
    , dropExtensions
    , takeExtensions
    , replaceExtensions
    , isExtensionOf
    , stripExtension

      -- * Combining
    , combine
    , (</>)
    , joinPath

      -- * Splitting
    , splitPath
    , splitDirectories

      -- * Trailing slash functions
    , hasTrailingPathSeparator
    , addTrailingPathSeparator
    , dropTrailingPathSeparator

      -- * File name manipulations
    , normalise
    , equal
    , isValid

      -- * Actions on paths
    , Actions
    , removeForcibly
    , rename
    , canonicalize

      -- * Base path class
    , Path
    )
where

import Effectful (Effect)
import Effectful.FileSystem (FileSystem)
import Prelude hiding (Any (..), abs, isPrefixOf, join)

import Data.List qualified as List
import Effectful.FileSystem qualified as FileSystem
import System.FilePath qualified as Path
import System.FilePath qualified as Reexports

import Atelier.FileSystem.Path.Internal
    ( Absolute (..)
    , Any (..)
    , Relative (..)
    , SafePath (..)
    , UnsafePath (..)
    )
import Atelier.FileSystem.Path.Symbol (abs, absolute, rel, relative)


-- | 'FileSystem.doesPathExist' for 'Absolute' paths.
exists :: (FileSystem :> es) => Absolute -> Eff es Bool
exists = FileSystem.doesPathExist . unsafeGetAbsolute


-- | Base path class for all general path operations.
class Path path where
    -- | Combine two paths with a path separator. The intention is that
    -- @readFile (dir \<\/\> file)@ will access the same file as
    -- @setCurrentDirectory dir; readFile file@.
    --
    -- Unlike "System.FilePath", this class\' '(</>)' only takes 'Relative'
    -- paths as its second argument, since "System.FilePath" would just return
    -- the second argument if it starts with a path separator or a drive letter
    -- (i.e. it is an absolute path).
    --
    -- >>> "/" </> "test"
    -- "/test"
    --
    -- >>> "home" </> "bob"
    -- "home/bob"
    --
    -- >>> "x:" </> "foo"
    -- "x:/foo"
    --
    -- See 'System.FilePath.</>'.
    (</>) :: path -> Relative -> path


    -- | Split a filename into directory and file. '</>' is the inverse. The
    -- first component will often end with a trailing slash.
    --
    -- See 'System.FilePath.splitFileName'.
    splitFileName :: path -> (path, Relative)


    -- | Get the file name.
    --
    -- See 'System.FilePath.takeFileName'.
    takeFileName :: path -> Relative


    -- | Set the filename.
    --
    -- See 'System.FilePath.replaceFileName'.
    replaceFileName :: path -> Relative -> path


    -- | Drop the filename. Unlike 'takeDirectory', this function will leave a
    -- trailing path separator on the directory.
    --
    -- See 'System.FilePath.dropFileName'.
    dropFileName :: path -> path


    -- | Get the base name, without an extension or path.
    --
    -- See 'System.FilePath.takeBaseName'.
    takeBaseName :: path -> String


    -- | Set the base name.
    --
    -- See 'System.FilePath.replaceBaseName'.
    replaceBaseName :: path -> String -> path


    -- | Get the directory name, move up one level.
    --
    -- See 'System.FilePath.takeDirectory'.
    takeDirectory :: path -> path


    -- | Set the directory, keeping the filename the same.
    --
    --
    -- >>> replaceDirectory "root/file.ext" "/directory/"
    -- "/directory/file.ext"
    --
    -- >>> Valid x => replaceDirectory x (takeDirectory x) `equalFilePath` x
    -- True
    --
    -- See 'System.FilePath.replaceDirectory'.
    replaceDirectory :: path -> path -> path


    -- | An alias for '</>'.
    combine :: path -> Relative -> path
    combine = (</>)


    -- | Split a path by the directory separator.
    --
    -- Since whether a path is determined by whether the first segment is
    -- absolute or not, this function retains the path kind for the first
    -- returned segment, while the rest of the path are 'Relative' segments.
    --
    -- >>> splitPath "/directory/file.ext"
    -- ("/", ["directory/","file.ext"])
    --
    -- >>> uncurry (:) (splitPath x)
    -- x
    --
    -- >>> splitPath "test//item/"
    -- ("test//", ["item/"])
    --
    -- >>> splitPath "test/item/file"
    -- ("test/", ["item/","file"])
    --
    -- >>> splitPath ""
    -- ("", [])
    --
    -- >>> splitPath "test"
    -- ("test", [])
    --
    -- >>> splitPath "/file/test"
    -- ("/", ["file/","test"])
    --
    -- See 'System.FilePath.splitPath'.
    splitPath :: path -> (path, [Relative])


    -- | Join path elements back together.
    --
    -- >>> joinPath y z
    -- foldr (</>) "" (y : z)
    --
    -- >>> joinPath "/" ["directory/","file.ext"]
    -- "/directory/file.ext"
    --
    -- >>> Valid x => uncurry joinPath (splitPath x)
    -- x
    --
    -- >>> joinPath "" []
    -- ""
    --
    -- >>> joinPath "test" ["file","path"]
    -- "test/file/path"
    --
    -- See 'System.FilePath.joinPath'.
    joinPath :: path -> [Relative] -> path


    -- | Just as 'splitPath', but don't add the trailing slashes to each element.
    --
    -- >>> splitDirectories "/directory/file.ext"
    -- ("/", ["directory","file.ext"])
    --
    -- >>> splitDirectories "test/file"
    -- ("", ["test","file"])
    --
    -- >>> splitDirectories "/test/file"
    -- ("/", ["test","file"])
    --
    -- >>> Valid x => uncurry joinPath (splitDirectories x) `equal` x
    -- True
    --
    -- >>> splitDirectories ""
    -- ("", [])
    --
    -- >>> splitDirectories "test"
    -- ("test", [])
    --
    -- >>> splitDirectories "/test///file"
    -- ("/", ["test","file"])
    --
    -- See 'System.FilePath.splitDirectories'.
    splitDirectories :: path -> (path, [Relative])


    -- | Normalise a file
    --
    -- - @\/\/@ outside of the drive can be made blank
    -- - @\/@ -> 'pathSeparator'
    -- - @.\/@ -> @""@
    --
    -- Does not remove @".."@, because of symlinks.
    --
    --
    -- >>> normalise "/file/\\test////"
    -- "/file/\\test/"
    --
    -- >>> normalise "/file/./test"
    -- "/file/test"
    --
    -- >>> normalise "/test/file/../bob/fred/"
    -- "/test/file/../bob/fred/"
    --
    -- >>> normalise "../bob/fred/"
    -- "../bob/fred/"
    --
    -- >>> normalise "/a/../c"
    -- "/a/../c"
    --
    -- >>> normalise "./bob/fred/"
    -- "bob/fred/"
    --
    -- >>> normalise "."
    -- "."
    --
    -- >>> normalise "./"
    -- "./"
    --
    -- >>> normalise "./."
    -- "./"
    --
    -- >>> normalise "/./"
    -- "/"
    --
    -- >>> normalise "/"
    -- "/"
    --
    -- >>> normalise "bob/fred/."
    -- "bob/fred/"
    --
    -- >>> normalise "//home"
    -- "/home"
    --
    -- See 'System.FilePath.normalise'.
    normalise :: path -> path


    -- | Equality of two @path@s. If you call 'canonicalize' first this has a
    -- much better chance of working. Note that this doesn't follow symlinks.
    --
    -- Similar to 'normalise', this does not expand @".."@, because of
    -- symlinks.
    --
    -- >>> x == y
    -- equal x y
    --
    -- >>> normalise x == normalise y
    -- equal x y
    --
    -- >>> equal "foo" "foo\/"
    -- True
    --
    -- >>> equal "\/a\/..\/c" "\/c"
    -- False
    --
    -- >>> equal "foo" "\/foo"
    -- False
    --
    -- >>> equal "foo" "FOO"
    -- False
    --
    -- See 'System.FilePath.equalFilePath'.
    equal :: path -> path -> Bool


    -- | Is a FilePath valid, i.e. could you create a file like it? This
    -- function checks for invalid names, and invalid characters, but does not
    -- check if length limits are exceeded, as these are typically filesystem
    -- dependent.
    --
    -- >>> isValid ""
    -- False
    --
    -- >>> isValid "\0"
    -- False
    --
    -- >>> isValid "/random_ path:*"
    -- True
    --
    -- >>> isValid x
    -- not (null x)
    --
    -- See 'System.FilePath.isValid'.
    isValid :: path -> Bool


    -- | Check whether one path is the strict parent/prefix of another.
    --
    -- >>> "/foo" `isPrefixOf` "/foo/bar"
    -- True
    --
    -- >>> "/foo/bar" `isPrefixOf` "/foo/quack"
    -- False
    --
    -- >>> "foo" `isPrefixOf` "foo/bar"
    -- True
    --
    -- >>> "foo/" `isPrefixOf` "foo/bar"
    -- True
    --
    -- >>> "foo" `isPrefixOf` "foo"
    -- True
    isPrefixOf :: path -> path -> Bool


    -- | Check whether a relative path is the suffix of another path.
    --
    -- >>> "bar" `isSuffixOf` "bar"
    -- True
    --
    -- >>> "bar" `isSuffixOf` "foo/bar"
    -- True
    --
    -- >>> "bar" `isSuffixOf` "/foo/bar"
    -- True
    --
    -- >>> "bar" `isSuffixOf` "/foo/bar/baz"
    -- False
    isSuffixOf :: Relative -> path -> Bool


    -- | Is an item either a directory or the last character a path separator?
    --
    -- >>> hasTrailingPathSeparator "test"
    -- False
    --
    -- >>> hasTrailingPathSeparator "test/"
    -- True
    --
    -- See 'System.FilePath.hasTrailingPathSeparator'.
    hasTrailingPathSeparator :: path -> Bool


    -- | Add a trailing file path separator if one is not already present.
    --
    -- >>> hasTrailingPathSeparator (addTrailingPathSeparator x)
    -- True
    --
    -- >>> addTrailingPathSeparator "test/rest"
    -- "test/rest/"
    --
    -- See 'System.FilePath.addTrailingPathSeparator'.
    addTrailingPathSeparator :: path -> path


    -- | Remove any trailing path separators
    --
    -- >>> dropTrailingPathSeparator "file/test/"
    -- "file/test"
    --
    -- >>> dropTrailingPathSeparator "/"
    -- "/"
    --
    -- >>> hasTrailingPathSeparator (dropTrailingPathSeparator x)
    -- False
    --
    -- See 'System.FilePath.dropTrailingPathSeparator'.
    dropTrailingPathSeparator :: path -> path


    -- | Split on the extension. 'addExtension' is the inverse.
    --
    -- >>> splitExtension "/directory/path.ext"
    -- ("/directory/path",".ext")
    --
    -- >>> uncurry (<>) (splitExtension x)
    -- x
    --
    -- >>> Valid x => uncurry addExtension (splitExtension x)
    -- x
    --
    -- >>> splitExtension "file.txt"
    -- ("file",".txt")
    --
    -- >>> splitExtension "file"
    -- ("file","")
    --
    -- >>> splitExtension "file/file.txt"
    -- ("file/file",".txt")
    --
    -- >>> splitExtension "file.txt/boris"
    -- ("file.txt/boris","")
    --
    -- >>> splitExtension "file.txt/boris.ext"
    -- ("file.txt/boris",".ext")
    --
    -- >>> splitExtension "file/path.txt.bob.fred"
    -- ("file/path.txt.bob",".fred")
    --
    -- >>> splitExtension "file/path.txt/"
    -- ("file/path.txt/","")
    --
    -- See 'System.FilePath.splitExtension'.
    splitExtension :: path -> (path, String)


    -- | Get the extension of a file, returns @""@ for no extension, @.ext@
    -- otherwise.
    --
    -- >>> takeExtension "/directory/path.ext"
    -- ".ext"
    --
    -- >>> takeExtension x
    -- snd (splitExtension x)
    --
    -- >>> Valid x => takeExtension (addExtension x "ext")
    -- ".ext"
    --
    -- >>> Valid x => takeExtension (replaceExtension x "ext")
    -- ".ext"
    --
    -- See 'System.FilePath.takeExtension'.
    takeExtension :: path -> String


    -- | Set the extension of a file, overwriting one if already present,
    -- equivalent to '-<.>'.
    --
    -- >>> replaceExtension "/directory/path.txt" "ext"
    -- "/directory/path.ext"
    --
    -- >>> replaceExtension "/directory/path.txt" ".ext"
    -- "/directory/path.ext"
    --
    -- >>> replaceExtension "file.txt" ".bob"
    -- "file.bob"
    --
    -- >>> replaceExtension "file.txt" "bob"
    -- "file.bob"
    --
    -- >>> replaceExtension "file" ".bob"
    -- "file.bob"
    --
    -- >>> replaceExtension "file.txt" ""
    -- "file"
    --
    -- >>> replaceExtension "file.fred.bob" "txt"
    -- "file.fred.txt"
    --
    -- >>> replaceExtension x y
    -- addExtension (dropExtension x) y
    --
    -- See 'System.FilePath.replaceExtension'.
    replaceExtension :: path -> String -> path
    replaceExtension = (-<.>)


    -- | Remove the current extension and add another, equivalent to
    -- 'replaceExtension'.
    --
    -- >>> "/directory/path.txt" -<.> "ext"
    -- "/directory/path.ext"
    --
    -- >>> "/directory/path.txt" -<.> ".ext"
    -- "/directory/path.ext"
    --
    -- >>> "foo.o" -<.> "c"
    -- "foo.c"
    --
    -- See 'System.FilePath.-<.>'.
    (-<.>) :: path -> String -> path


    -- | Remove last extension, and the @"."@ preceding it.
    --
    -- >>> dropExtension "/directory/path.ext"
    -- "/directory/path"
    --
    -- >>> dropExtension x
    -- fst (splitExtension x)
    --
    -- See 'System.FilePath.dropExtension'.
    dropExtension :: path -> path


    -- | Add an extension, even if there is already one there, equivalent to
    -- '<.>'.
    --
    -- >>> addExtension "/directory/path" "ext"
    -- "/directory/path.ext"
    --
    -- >>> addExtension "file.txt" "bib"
    -- "file.txt.bib"
    --
    -- >>> addExtension "file." ".bib"
    -- "file..bib"
    --
    -- >>> addExtension "file" ".bib"
    -- "file.bib"
    --
    -- >>> addExtension "/" "x"
    -- "/.x"
    --
    -- >>> addExtension x ""
    -- x
    --
    -- >>> Valid x => takeFileName (addExtension (addTrailingPathSeparator x) "ext")
    -- ".ext"
    --
    -- See 'System.FilePath.addExtension'.
    addExtension :: path -> String -> path
    addExtension = (<.>)


    -- | Does the given filename have an extension?
    --
    -- >>> hasExtension "/directory/path.ext"
    -- True
    --
    -- >>> hasExtension "/directory/path"
    -- False
    --
    -- >>> null (takeExtension x)
    -- not (hasExtension x)
    --
    -- See 'System.FilePath.hasExtension'.
    hasExtension :: path -> Bool


    -- | Add an extension, even if there is already one there, equivalent to
    -- 'addExtension'.
    --
    -- >>> "/directory/path" <.> "ext"
    -- "/directory/path.ext"
    --
    -- >>> "/directory/path" <.> ".ext"
    -- "/directory/path.ext"
    --
    -- See 'System.FilePath.<.>'.
    (<.>) :: path -> String -> path


    -- | Split on all extensions.
    --
    -- >>> splitExtensions "/directory/path.ext"
    -- ("/directory/path",".ext")
    --
    -- >>> splitExtensions "file.tar.gz"
    -- ("file",".tar.gz")
    --
    -- >>> uncurry (<>) (splitExtensions x)
    -- x
    --
    -- >>> Valid x => uncurry addExtension (splitExtensions x)
    -- x
    --
    -- See 'System.FilePath.splitExtensions'.
    splitExtensions :: path -> (path, String)


    -- | Drop all extensions.
    --
    -- >>> dropExtensions "/directory/path.ext"
    -- "/directory/path"
    --
    -- >>> dropExtensions "file.tar.gz"
    -- "file"
    --
    -- >>> hasExtension (dropExtensions x)
    -- False
    --
    -- >>> any isExtSeparator (takeFileName (dropExtensions x))
    -- False
    --
    -- See 'System.FilePath.dropExtensions'.
    dropExtensions :: path -> path


    -- | Get all extensions.
    --
    -- >>> takeExtensions "/directory/path.ext"
    -- ".ext"
    --
    -- >>> takeExtensions "file.tar.gz"
    -- ".tar.gz"
    --
    -- See 'System.FilePath.takeExtensions'.
    takeExtensions :: path -> String


    -- | Replace all extensions of a file with a new extension. Note that
    -- 'replaceExtension' and 'addExtension' both work for adding multiple
    -- extensions, so only required when you need to drop all extensions first.
    --
    -- >>> replaceExtensions "file.fred.bob" "txt"
    -- "file.txt"
    --
    -- >>> replaceExtensions "file.fred.bob" "tar.gz"
    -- "file.tar.gz"
    --
    -- See 'System.FilePath.replaceExtensions'.
    replaceExtensions :: path -> String -> path


    -- | Does the given filename have the specified extension?
    --
    -- >>> "png" `isExtensionOf` "/directory/file.png"
    -- True
    --
    -- >>> ".png" `isExtensionOf` "/directory/file.png"
    -- True
    --
    -- >>> ".tar.gz" `isExtensionOf` "bar/foo.tar.gz"
    -- True
    --
    -- >>> "ar.gz" `isExtensionOf` "bar/foo.tar.gz"
    -- False
    --
    -- >>> "png" `isExtensionOf` "/directory/file.png.jpg"
    -- False
    --
    -- >>> "csv/table.csv" `isExtensionOf` "/data/csv/table.csv"
    -- False
    --
    -- See 'System.FilePath.isExtensionOf'.
    isExtensionOf :: String -> path -> Bool


    -- | Drop the given extension from a @path@, and the @"."@ preceding it.
    -- Returns 'Nothing' if the @path@ does not have the given extension, or
    -- 'Just' and the part before the extension if it does.
    --
    -- This function can be more predictable than 'dropExtensions', especially
    -- if the filename might itself contain @.@ characters.
    --
    -- >>> stripExtension "hs.o" "foo.x.hs.o"
    -- Just "foo.x"
    --
    -- >>> stripExtension "hi.o" "foo.x.hs.o"
    -- Nothing
    --
    -- >>> dropExtension x
    -- fromJust (stripExtension (takeExtension x) x)
    --
    -- >>> dropExtensions x
    -- fromJust (stripExtension (takeExtensions x) x)
    --
    -- >>> stripExtension ".c.d" "a.b.c.d"
    -- Just "a.b"
    --
    -- >>> stripExtension ".c.d" "a.b..c.d"
    -- Just "a.b."
    --
    -- >>> stripExtension "baz" "foo.bar"
    -- Nothing
    --
    -- >>> stripExtension "bar" "foobar"
    -- Nothing
    --
    -- >>> stripExtension "" x
    -- Just x
    --
    -- See 'System.FilePath.stripExtension'.
    stripExtension :: String -> path -> Maybe path


    -- | Contract a filename, based on a relative path. Note that the resulting
    -- path will never introduce `..` paths, as the presence of symlinks means
    -- `../b` may not reach `a/b` if it starts from `a/c`.
    --
    -- >>> makeRelative "/directory" "/directory/file.ext"
    -- "file.ext"
    --
    -- >>> Valid x => makeRelative (takeDirectory x) x `equal` takeFileName x
    -- True
    --
    -- >>> makeRelative x x
    -- "."
    --
    -- >>> Valid x y => equal x y || (isRelative x && makeRelative y x == x) || equal (y </> makeRelative y x) x
    -- True
    --
    -- >>> makeRelative "/Home" "/home/bob"
    -- "/home/bob"
    --
    -- >>> makeRelative "/home/" "/home/bob/foo/bar"
    -- "bob/foo/bar"
    --
    -- >>> makeRelative "/fred" "bob"
    -- "bob"
    --
    -- >>> makeRelative "/file/test" "/file/test/fred"
    -- "fred"
    --
    -- >>> makeRelative "/file/test" "/file/test/fred/"
    -- "fred/"
    --
    -- >>> makeRelative "some/path" "some/path/a/b/c"
    -- "a/b/c"
    --
    -- See 'System.FilePath.makeRelative'.
    makeRelative :: path -> path -> Relative


    -- | Get the underlying 'FilePath'.
    toFilePath :: path -> FilePath


    -- | Create a 'path' from a 'FilePath'.
    fromFilePath :: FilePath -> Either Text path


-- | Defined as lifted operations over "System.FilePath" operations.
deriving via (SafePath Absolute) instance Path Absolute


-- | Defined as lifted operations over "System.FilePath" operations.
deriving via (SafePath Relative) instance Path Relative


infixr 5 </>


infixr 7 <.>


infixr 7 -<.>


-- | Effectful operations on 'Path' paths. Manipulates items on the file
-- system.
class Actions es path where
    -- | 'Effectful.FileSystem.removePathForcibly' for 'Absolute' and 'Relative' paths.
    removeForcibly :: path -> Eff es ()


    -- | 'Effectful.FileSystem.renameFile' for 'Absolute' and 'Relative' paths.
    rename :: path -> path -> Eff es ()


    -- | 'Effectful.FileSystem.canonicalizePath' for 'Absolute' and 'Relative' paths.
    canonicalize :: path -> Eff es Absolute


-- | Lifted operations from "Effectful.FileSystem" for 'Absolute'.
deriving via (SafePath Absolute) instance (FileSystem :> es) => Actions es Absolute


-- | Lifted operations from "Effectful.FileSystem" for 'Relative'.
deriving via (SafePath Relative) instance (FileSystem :> es) => Actions es Relative


-- | Convert an 'Absolute' path to a 'Relative' path relative to the current directory.
makeRelativeToCurrentDirectory :: (FileSystem :> es) => Absolute -> Eff es Relative
makeRelativeToCurrentDirectory (UnsafeMkAbsolute path) =
    UnsafeMkRelative <$> FileSystem.makeRelativeToCurrentDirectory path


-- | Convert a 'Relative' path into an 'Absolute' path relative to the current directory.
makeAbsolute :: (FileSystem :> es) => Relative -> Eff es Absolute
makeAbsolute (UnsafeMkRelative path) = UnsafeMkAbsolute <$> FileSystem.makeAbsolute path


-- | Convenience instance for deriving 'Path' instances with just some basic
-- operations.
instance (UnsafePath path) => Path (SafePath path) where
    SafePath p1 </> UnsafeMkRelative p2 =
        SafePath $ unsafeToPath $ unsafeFromPath p1 Path.</> p2


    splitFileName =
        bimap (SafePath . unsafeToPath) UnsafeMkRelative
            . Path.splitFileName
            . unsafeFromPath
            . getSafePath


    takeFileName =
        UnsafeMkRelative
            . Path.takeFileName
            . unsafeFromPath
            . getSafePath


    replaceFileName (SafePath absPath) (UnsafeMkRelative relPath) =
        SafePath
            $ unsafeToPath
            $ Path.replaceFileName (unsafeFromPath absPath) relPath


    dropFileName = fmap $ unsafeMapPath Path.dropFileName


    takeBaseName = Path.takeBaseName . unsafeFromPath . getSafePath


    replaceBaseName (SafePath path) baseName =
        SafePath
            $ unsafeToPath
            $ Path.replaceBaseName (unsafeFromPath path) baseName


    takeDirectory = fmap $ unsafeMapPath Path.takeDirectory


    replaceDirectory (SafePath path) (SafePath replacement) =
        SafePath
            $ unsafeToPath
            $ Path.replaceDirectory (unsafeFromPath path)
            $ unsafeFromPath replacement


    splitPath (SafePath path) =
        case Path.splitPath $ unsafeFromPath path of
            x : xs -> (SafePath $ unsafeToPath x, UnsafeMkRelative <$> xs)
            [] -> (SafePath $ unsafeToPath "", []) -- Should never happen with an absolute path


    joinPath (SafePath path) segments =
        SafePath
            $ unsafeToPath
            $ Path.joinPath
            $ unsafeFromPath path : (unsafeGetRelative <$> segments)


    splitDirectories (SafePath path) =
        case Path.splitDirectories $ unsafeFromPath path of
            x : xs -> (SafePath $ unsafeToPath x, UnsafeMkRelative <$> xs)
            _ -> (SafePath $ unsafeToPath "", []) -- should never happen with an absolute path


    normalise = fmap $ unsafeMapPath Path.normalise


    equal = Path.equalFilePath `on` unsafeFromPath . getSafePath


    isValid = Path.isValid . unsafeFromPath . getSafePath


    isPrefixOf (SafePath p1) (SafePath p2) =
        Path.addTrailingPathSeparator (unsafeFromPath p1)
            `List.isPrefixOf` unsafeFromPath p2


    isSuffixOf (UnsafeMkRelative child) (SafePath parent) =
        Path.normalise child
            `List.isSuffixOf` Path.normalise (unsafeFromPath parent)


    hasTrailingPathSeparator =
        Path.hasTrailingPathSeparator . unsafeFromPath . getSafePath


    addTrailingPathSeparator =
        fmap $ unsafeMapPath Path.addTrailingPathSeparator


    dropTrailingPathSeparator =
        fmap $ unsafeMapPath Path.dropTrailingPathSeparator


    splitExtension =
        first (SafePath . unsafeToPath)
            . Path.splitExtension
            . unsafeFromPath
            . getSafePath


    takeExtension = Path.takeExtension . unsafeFromPath . getSafePath


    SafePath path -<.> ext =
        SafePath $ unsafeToPath $ unsafeFromPath path Path.-<.> ext


    dropExtension = fmap $ unsafeMapPath Path.dropExtension


    hasExtension = Path.hasExtension . unsafeFromPath . getSafePath


    SafePath path <.> ext =
        SafePath $ unsafeToPath $ Path.addExtension (unsafeFromPath path) ext


    splitExtensions =
        first (SafePath . unsafeToPath)
            . Path.splitExtensions
            . unsafeFromPath
            . getSafePath


    dropExtensions = fmap $ unsafeMapPath Path.dropExtensions


    takeExtensions = Path.takeExtensions . unsafeFromPath . getSafePath


    replaceExtensions (SafePath path) =
        SafePath
            . unsafeToPath
            . Path.replaceExtensions (unsafeFromPath path)


    isExtensionOf ext = Path.isExtensionOf ext . unsafeFromPath . getSafePath


    stripExtension ext =
        fmap (SafePath . unsafeToPath)
            . Path.stripExtension ext
            . unsafeFromPath
            . getSafePath


    makeRelative (SafePath p1) (SafePath p2) =
        UnsafeMkRelative $ (Path.makeRelative `on` unsafeFromPath) p1 p2


    toFilePath = unsafeFromPath . getSafePath


    fromFilePath = fmap SafePath . safeToPath


instance (FileSystem :> es, UnsafePath path) => Actions (es :: [Effect]) (SafePath path) where
    removeForcibly = FileSystem.removePathForcibly . unsafeFromPath . getSafePath
    rename = FileSystem.renamePath `on` unsafeFromPath . getSafePath
    canonicalize = fmap UnsafeMkAbsolute . FileSystem.canonicalizePath . unsafeFromPath . getSafePath


-- | Simplify operations on 'Any' paths for cases where you don't need to know
-- specifically whether it's an 'Absolute' or 'Relative' path.
withAny :: (forall path. (Path path) => path -> a) -> Any -> a
withAny f = \case
    Absolute p -> f p
    Relative p -> f p


-- | Simplify manipulating the path in an 'Any' for cases where you don't need
-- to know specifically whether it's an 'Absolute' or 'Relative' path. Usually
-- you can just use the 'Path' instance for 'Any' instead, but this function is
-- included here for completeness sake.
--
-- >>> mapAny normalise (absolute @"/foo")
mapAny :: (forall path. (Path path) => path -> path) -> Any -> Any
mapAny f = \case
    Absolute p -> Absolute $ f p
    Relative p -> Relative $ f p


-- | Delegates to 'Absolute' and 'Relative' where applicable. Comparisons
-- return 'False' if the two 'Any's being compared have different types of
-- paths.
instance Path Any where
    Absolute p1 </> p2 = Absolute $ p1 </> p2
    Relative p1 </> p2 = Relative $ p1 </> p2
    splitFileName (Absolute p) = first Absolute $ splitFileName p
    splitFileName (Relative p) = first Relative $ splitFileName p
    takeFileName = withAny takeFileName
    replaceFileName (Absolute p1) p2 = Absolute $ replaceFileName p1 p2
    replaceFileName (Relative p1) p2 = Relative $ replaceFileName p1 p2
    dropFileName = mapAny dropFileName
    takeBaseName = withAny takeBaseName
    replaceBaseName (Absolute p) baseName = Absolute $ replaceBaseName p baseName
    replaceBaseName (Relative p) baseName = Relative $ replaceBaseName p baseName
    takeDirectory = mapAny takeDirectory
    replaceDirectory (Absolute path) (Absolute replacement) = Absolute $ replaceDirectory path replacement
    replaceDirectory (Relative path) (Relative replacement) = Relative $ replaceDirectory path replacement
    replaceDirectory (Absolute path) (Relative replacement) =
        Relative
            $ UnsafeMkRelative
            $ Path.replaceDirectory (unsafeFromPath path) (unsafeFromPath replacement)
    replaceDirectory (Relative path) (Absolute replacement) =
        Absolute
            $ UnsafeMkAbsolute
            $ Path.replaceDirectory (unsafeFromPath path) (unsafeFromPath replacement)
    splitPath (Absolute p) = first Absolute $ splitPath p
    splitPath (Relative p) = first Relative $ splitPath p
    joinPath (Absolute p) segs = Absolute $ joinPath p segs
    joinPath (Relative p) segs = Relative $ joinPath p segs
    splitDirectories (Absolute p) = first Absolute $ splitDirectories p
    splitDirectories (Relative p) = first Relative $ splitDirectories p
    normalise = mapAny normalise
    equal (Absolute p1) (Absolute p2) = equal p1 p2
    equal (Relative p1) (Relative p2) = equal p1 p2
    equal _ _ = False
    isValid = withAny isValid
    isPrefixOf (Absolute p1) (Absolute p2) = isPrefixOf p1 p2
    isPrefixOf (Relative p1) (Relative p2) = isPrefixOf p1 p2
    isPrefixOf _ _ = False
    isSuffixOf p1 (Absolute p2) = isSuffixOf p1 p2
    isSuffixOf p1 (Relative p2) = isSuffixOf p1 p2
    hasTrailingPathSeparator = withAny hasTrailingPathSeparator
    addTrailingPathSeparator = mapAny addTrailingPathSeparator
    dropTrailingPathSeparator = mapAny dropTrailingPathSeparator
    splitExtension (Absolute p) = first Absolute $ splitExtension p
    splitExtension (Relative p) = first Relative $ splitExtension p
    takeExtension = withAny takeExtension
    Absolute p -<.> ext = Absolute $ p -<.> ext
    Relative p -<.> ext = Relative $ p -<.> ext
    dropExtension = mapAny dropExtension
    hasExtension = withAny hasExtension
    Absolute p <.> ext = Absolute $ p <.> ext
    Relative p <.> ext = Relative $ p <.> ext
    splitExtensions (Absolute p) = first Absolute $ splitExtensions p
    splitExtensions (Relative p) = first Relative $ splitExtensions p
    dropExtensions = mapAny dropExtensions
    takeExtensions = withAny takeExtensions
    replaceExtensions (Absolute p) ext = Absolute $ replaceExtensions p ext
    replaceExtensions (Relative p) ext = Relative $ replaceExtensions p ext
    isExtensionOf ext = withAny (isExtensionOf ext)
    stripExtension ext (Absolute p) = Absolute <$> stripExtension ext p
    stripExtension ext (Relative p) = Relative <$> stripExtension ext p
    makeRelative p1 p2 = UnsafeMkRelative $ Path.makeRelative (toFilePath p1) (toFilePath p2)
    toFilePath = withAny toFilePath
    fromFilePath path
        | Path.isAbsolute path = Absolute <$> fromFilePath path
        | otherwise = Relative <$> fromFilePath path
