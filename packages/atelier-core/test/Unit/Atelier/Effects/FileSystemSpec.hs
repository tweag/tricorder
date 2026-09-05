module Unit.Atelier.Effects.FileSystemSpec (spec_FileSystem) where

import Control.Exception (evaluate)
import Effectful (runPureEff)
import Effectful.State.Static.Shared (State, evalState)
import Test.Hspec (Spec, anyIOException, describe, it, shouldBe, shouldThrow)

import Data.ByteString.Lazy qualified as LBS
import Data.Map.Strict qualified as M

import Atelier.Effects.FileSystem


spec_FileSystem :: Spec
spec_FileSystem = describe "runFileSystemState" testFileSystemState


testFileSystemState :: Spec
testFileSystemState = do
    describe "readFileBs" do
        it "reads bytes of a file present in the state" do
            run (M.singleton "/a" "hello") (readFileBs "/a")
                `shouldBe` "hello"

        it "errors when the file is absent" do
            evaluate (run M.empty (readFileBs "/missing"))
                `shouldThrow` anyIOException

    describe "readFileLbs" do
        it "reads the entire file as lazy bytes" do
            run (M.singleton "/a" "hello") (readFileLbs "/a")
                `shouldBe` ("hello" :: LBS.ByteString)

        it "errors when the file is absent" do
            evaluate (run M.empty (readFileLbs "/missing"))
                `shouldThrow` anyIOException

    describe "readFileLbsFrom" do
        it "returns full content when offset is 0" do
            run (M.singleton "/a" "hello") (readFileLbsFrom "/a" 0)
                `shouldBe` ("hello" :: LBS.ByteString)

        it "skips the leading bytes up to the given offset" do
            run (M.singleton "/a" "hello") (readFileLbsFrom "/a" 2)
                `shouldBe` ("llo" :: LBS.ByteString)

        it "returns empty when offset equals the file length" do
            run (M.singleton "/a" "hello") (readFileLbsFrom "/a" 5)
                `shouldBe` ("" :: LBS.ByteString)

        it "errors when the file is absent" do
            evaluate (run M.empty (readFileLbsFrom "/missing" 0))
                `shouldThrow` anyIOException

    describe "doesFileExist" do
        it "returns True for a key present in the state" do
            run (M.singleton "/a" "") (doesFileExist "/a")
                `shouldBe` True

        it "returns False when the key is absent" do
            run M.empty (doesFileExist "/a")
                `shouldBe` False

    describe "doesPathExist" do
        it "returns True when a key with the path as a string prefix exists" do
            run (M.singleton "/dir/file" "") (doesPathExist "/dir")
                `shouldBe` True

        it "returns False when no key shares the prefix" do
            run M.empty (doesPathExist "/dir")
                `shouldBe` False

        it "returns False for an exact-match key with no children" do
            run (M.singleton "/dir" "") (doesPathExist "/dir")
                `shouldBe` False

    describe "listDirectory" do
        it "returns all keys that start with the given path" do
            let fs = M.fromList [("/dir/a", ""), ("/dir/b", ""), ("/other/c", "")]
            sort (run fs (listDirectory "/dir"))
                `shouldBe` ["/dir/a", "/dir/b"]

        it "returns empty list when no keys share the prefix" do
            run M.empty (listDirectory "/dir")
                `shouldBe` []

        it "excludes an exact-match key" do
            let fs = M.fromList [("/dir", ""), ("/dir/a", "")]
            run fs (listDirectory "/dir")
                `shouldBe` ["/dir/a"]

    describe "removeFile" do
        it "removes the file from the state" do
            let result = run (M.singleton "/a" "x") do
                    removeFile "/a"
                    doesFileExist "/a"
            result `shouldBe` False

        it "leaves other files unaffected" do
            let result = run (M.fromList [("/a", "x"), ("/b", "y")]) do
                    removeFile "/a"
                    doesFileExist "/b"
            result `shouldBe` True

        it "is a no-op when the file is absent" do
            let result = run M.empty do
                    removeFile "/missing"
                    doesFileExist "/missing"
            result `shouldBe` False

    describe "createDirectoryIfMissing" do
        it "is a no-op — does not add any entries to the state" do
            let result = run M.empty do
                    createDirectoryIfMissing True "/new/dir"
                    doesPathExist "/new/dir"
            result `shouldBe` False

    describe "canonicalizePath" do
        it "returns the path unchanged" do
            run M.empty (canonicalizePath "/some/./path")
                `shouldBe` "/some/./path"

    describe "getCurrentDirectory" do
        it "returns /" do
            run M.empty getCurrentDirectory
                `shouldBe` "/"

    describe "getXdgRuntimeDir" do
        it "returns /tmp" do
            run M.empty getXdgRuntimeDir
                `shouldBe` "/tmp"


run
    :: Map FilePath ByteString
    -> Eff '[FileSystem, State (Map FilePath ByteString)] a
    -> a
run fs = runPureEff . evalState fs . runFileSystemState
