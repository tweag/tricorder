module Unit.Atelier.Effects.FileSystemSpec (test_FileSystem) where

import Control.Exception (IOException, evaluate, try)
import Effectful (runPureEff)
import Effectful.State.Static.Shared (State, evalState)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.ByteString.Lazy qualified as LBS
import Data.Map.Strict qualified as M

import Atelier.Effects.FileSystem


test_FileSystem :: TestTree
test_FileSystem =
    testGroup
        "FileSystem"
        [ testGroup "runFileSystemState" testFileSystemState
        ]


testFileSystemState :: [TestTree]
testFileSystemState =
    [ testGroup
        "readFileBs"
        [ testCase "reads bytes of a file present in the state" do
            run (M.singleton "/a" "hello") (readFileBs "/a")
                @?= "hello"
        , testCase "errors when the file is absent" do
            result <- try @IOException $ evaluate (run M.empty (readFileBs "/missing"))
            isLeft result @?= True
        ]
    , testGroup
        "readFileLbs"
        [ testCase "reads the entire file as lazy bytes" do
            run (M.singleton "/a" "hello") (readFileLbs "/a")
                @?= ("hello" :: LBS.ByteString)
        , testCase "errors when the file is absent" do
            result <- try @IOException $ evaluate (run M.empty (readFileLbs "/missing"))
            isLeft result @?= True
        ]
    , testGroup
        "readFileLbsFrom"
        [ testCase "returns full content when offset is 0" do
            run (M.singleton "/a" "hello") (readFileLbsFrom "/a" 0)
                @?= ("hello" :: LBS.ByteString)
        , testCase "skips the leading bytes up to the given offset" do
            run (M.singleton "/a" "hello") (readFileLbsFrom "/a" 2)
                @?= ("llo" :: LBS.ByteString)
        , testCase "returns empty when offset equals the file length" do
            run (M.singleton "/a" "hello") (readFileLbsFrom "/a" 5)
                @?= ("" :: LBS.ByteString)
        , testCase "errors when the file is absent" do
            result <- try @IOException $ evaluate (run M.empty (readFileLbsFrom "/missing" 0))
            isLeft result @?= True
        ]
    , testGroup
        "doesFileExist"
        [ testCase "returns True for a key present in the state" do
            run (M.singleton "/a" "") (doesFileExist "/a")
                @?= True
        , testCase "returns False when the key is absent" do
            run M.empty (doesFileExist "/a")
                @?= False
        ]
    , testGroup
        "doesPathExist"
        [ testCase "returns True when a key with the path as a string prefix exists" do
            run (M.singleton "/dir/file" "") (doesPathExist "/dir")
                @?= True
        , testCase "returns False when no key shares the prefix" do
            run M.empty (doesPathExist "/dir")
                @?= False
        , testCase "returns False for an exact-match key with no children" do
            run (M.singleton "/dir" "") (doesPathExist "/dir")
                @?= False
        ]
    , testGroup
        "listDirectory"
        [ testCase "returns all keys that start with the given path" do
            let fs = M.fromList [("/dir/a", ""), ("/dir/b", ""), ("/other/c", "")]
            sort (run fs (listDirectory "/dir"))
                @?= ["/dir/a", "/dir/b"]
        , testCase "returns empty list when no keys share the prefix" do
            run M.empty (listDirectory "/dir")
                @?= []
        , testCase "excludes an exact-match key" do
            let fs = M.fromList [("/dir", ""), ("/dir/a", "")]
            run fs (listDirectory "/dir")
                @?= ["/dir/a"]
        ]
    , testGroup
        "removeFile"
        [ testCase "removes the file from the state" do
            let result = run (M.singleton "/a" "x") do
                    removeFile "/a"
                    doesFileExist "/a"
            result @?= False
        , testCase "leaves other files unaffected" do
            let result = run (M.fromList [("/a", "x"), ("/b", "y")]) do
                    removeFile "/a"
                    doesFileExist "/b"
            result @?= True
        , testCase "is a no-op when the file is absent" do
            let result = run M.empty do
                    removeFile "/missing"
                    doesFileExist "/missing"
            result @?= False
        ]
    , testGroup
        "createDirectoryIfMissing"
        [ testCase "is a no-op — does not add any entries to the state" do
            let result = run M.empty do
                    createDirectoryIfMissing True "/new/dir"
                    doesPathExist "/new/dir"
            result @?= False
        ]
    , testGroup
        "canonicalizePath"
        [ testCase "returns the path unchanged" do
            run M.empty (canonicalizePath "/some/./path")
                @?= "/some/./path"
        ]
    , testGroup
        "getCurrentDirectory"
        [ testCase "returns /" do
            run M.empty getCurrentDirectory
                @?= "/"
        ]
    , testGroup
        "getXdgRuntimeDir"
        [ testCase "returns /tmp" do
            run M.empty getXdgRuntimeDir
                @?= "/tmp"
        ]
    ]


run
    :: Map FilePath ByteString
    -> Eff '[FileSystem, State (Map FilePath ByteString)] a
    -> a
run fs = runPureEff . evalState fs . runFileSystemState
