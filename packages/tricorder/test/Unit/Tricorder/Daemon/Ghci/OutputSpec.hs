module Unit.Tricorder.Daemon.Ghci.OutputSpec (test_Output) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Daemon.Ghci.Output (parseShowModules, parseShowTargets)


test_Output :: TestTree
test_Output =
    testGroup
        "Output"
        [ testGroup "parseShowModules" testParseShowModules
        , testGroup "parseShowTargets" testParseShowTargets
        ]


testParseShowModules :: [TestTree]
testParseShowModules =
    [ testGroup "typical output" testShowModules
    , testGroup "empty / blank input" testShowModulesEmpty
    ]


testShowModules :: [TestTree]
testShowModules =
    [ testCase "parses typical :show modules output" do
        let input =
                [ "Tricorder.Build     ( src/Tricorder.Build.hs, interpreted )"
                , "Tricorder.Session        ( src/Tricorder/Session.hs, interpreted )"
                , "Main                     ( app/Main.hs, interpreted )"
                ]
        parseShowModules input
            @?= [ ("Tricorder.Build", "src/Tricorder.Build.hs")
                , ("Tricorder.Session", "src/Tricorder/Session.hs")
                , ("Main", "app/Main.hs")
                ]
    , testCase "parses absolute paths" do
        parseShowModules ["Lib ( /home/user/project/src/Lib.hs, interpreted )"]
            @?= [("Lib", "/home/user/project/src/Lib.hs")]
    , testCase "strips ANSI codes before parsing" do
        parseShowModules ["\ESC[1mMain\ESC[0m                     ( app/Main.hs, interpreted )"]
            @?= [("Main", "app/Main.hs")]
    ]


testShowModulesEmpty :: [TestTree]
testShowModulesEmpty =
    [ testCase "returns empty list for empty input" do
        parseShowModules [] @?= []
    , testCase "returns empty list for blank lines" do
        parseShowModules ["", "   ", "\t"] @?= []
    , testCase "skips lines without '( '" do
        parseShowModules ["just some random text"] @?= []
    ]


testParseShowTargets :: [TestTree]
testParseShowTargets =
    [ testCase "parses module names emitted by cabal repl --enable-multi-repl" do
        parseShowTargets
            [ "Atelier.Effects.Cache"
            , "Atelier.Effects.Chan"
            , "Paths_tricorder"
            ]
            @?= ["Atelier.Effects.Cache", "Atelier.Effects.Chan", "Paths_tricorder"]
    , testCase "parses file-path targets emitted by plain ghci" do
        parseShowTargets ["src/Foo.hs", "test/Bar.hs"]
            @?= ["src/Foo.hs", "test/Bar.hs"]
    , testCase "strips the leading '*' marker for the active interactive target" do
        parseShowTargets ["*Main", "Foo.Bar"] @?= ["Main", "Foo.Bar"]
    , testCase "strips ANSI escape sequences" do
        parseShowTargets ["\ESC[1mFoo.Bar\ESC[0m"] @?= ["Foo.Bar"]
    , testCase "skips blank and whitespace-only lines" do
        parseShowTargets ["", "   ", "\t", "Real.Target"] @?= ["Real.Target"]
    , testCase "returns empty list for empty input" do
        parseShowTargets [] @?= []
    ]
