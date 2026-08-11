module Unit.Tricorder.SourceLookup.TarballSpec (spec_Tarball) where

import System.FilePath (isAbsolute, (</>))
import Test.Hspec

import Codec.Archive.Tar qualified as Tar
import Codec.Archive.Tar.Entry qualified as Tar
import Codec.Compression.GZip qualified as GZip
import Data.ByteString.Lazy qualified as BSL

import Tricorder.Module (splitPackageId)
import Tricorder.SourceLookup.Tarball
    ( cabalPackagesDirs
    , extractModule
    , matchesModule
    , tarballPath
    )


spec_Tarball :: Spec
spec_Tarball = do
    describe "splitPackageId" do
        it "splits a simple package id" do
            splitPackageId "aeson-2.2.5.0" `shouldBe` ("aeson", "2.2.5.0")

        it "keeps hyphens inside the package name" do
            splitPackageId "list-t-1.0.5.7" `shouldBe` ("list-t", "1.0.5.7")

    describe "tarballPath" do
        it "derives the cache path for a package id" do
            tarballPath "/c" "hackage.haskell.org" "aeson-2.2.5.0"
                `shouldBe` "/c" </> "hackage.haskell.org/aeson/2.2.5.0/aeson-2.2.5.0.tar.gz"

    describe "cabalPackagesDirs" do
        it "honors CABAL_DIR" do
            cabalPackagesDirs [("CABAL_DIR", "/cd")] `shouldBe` ["/cd/packages"]

        it "includes the legacy ~/.cabal location alongside the XDG one" do
            cabalPackagesDirs [("HOME", "/h")]
                `shouldBe` ["/h/.cache/cabal/packages", "/h/.cabal/packages"]

        it "yields no candidates (never a relative path) when HOME is unset" do
            cabalPackagesDirs [] `shouldBe` []

        it "only ever produces absolute candidates" do
            all isAbsolute (cabalPackagesDirs [("HOME", "/h"), ("XDG_CACHE_HOME", "/x")])
                `shouldBe` True

    describe "matchesModule" do
        it "matches a src/ layout entry" do
            matchesModule "Data.Aeson" "aeson-2.2.5.0/src/Data/Aeson.hs" `shouldBe` True

        it "matches a lib/ layout entry" do
            matchesModule "Data.Aeson" "aeson-2.2.5.0/lib/Data/Aeson.hs" `shouldBe` True

        it "matches a flat layout entry" do
            matchesModule "Data.Aeson" "aeson-2.2.5.0/Data/Aeson.hs" `shouldBe` True

        it "does not match a different module under the same prefix" do
            matchesModule "Data.Aeson" "aeson-2.2.5.0/src/Data/Aeson/Types.hs" `shouldBe` False

        it "does not match a deeper module whose final component coincides" do
            -- Module `Lens` must not resolve to the file for `Control.Lens`.
            matchesModule "Lens" "pkg-1.0/Control/Lens.hs" `shouldBe` False

        it "matches a preprocessed .hsc entry" do
            matchesModule "System.Posix.Files" "unix-2.8.5.0/System/Posix/Files.hsc" `shouldBe` True

        it "matches a literate .lhs entry" do
            matchesModule "Data.Ratio" "base-4.19.0.0/src/Data/Ratio.lhs" `shouldBe` True

    describe "extractModule" do
        it "extracts a member by module name" do
            extractModule "Data.Aeson" fixtureTarball `shouldBe` Just "module Data.Aeson where\n"

        it "returns Nothing when the module is absent" do
            extractModule "Data.Missing" fixtureTarball `shouldBe` Nothing

        it "prefers a library source path over a same-named test path" do
            extractModule "Data.Aeson" dupModuleTarball
                `shouldBe` Just "module Data.Aeson (lib) where\n"


-- | A gzipped tar with a single source member.
fixtureTarball :: LByteString
fixtureTarball = mkTarball [("aeson-2.2.5.0/src/Data/Aeson.hs", "module Data.Aeson where\n")]


-- | A gzipped tar in which the same module appears under both a test tree and
-- the library tree, with the test copy listed first.
dupModuleTarball :: LByteString
dupModuleTarball =
    mkTarball
        [ ("aeson-2.2.5.0/tests/Data/Aeson.hs", "module Data.Aeson (test) where\n")
        , ("aeson-2.2.5.0/src/Data/Aeson.hs", "module Data.Aeson (lib) where\n")
        ]


-- | Build a gzipped tar from @(path, contents)@ pairs, in the given order.
mkTarball :: [(FilePath, Text)] -> LByteString
mkTarball entries =
    GZip.compress (Tar.write [fileEntry path content | (path, content) <- entries])
  where
    fileEntry path content =
        Tar.fileEntry
            (either (error . toText) id (Tar.toTarPath False path))
            (BSL.fromStrict (encodeUtf8 content))
