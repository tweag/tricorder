module Unit.Tricorder.CLI.RenderSpec (test_Render) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertBool, testCase)

import Data.Text qualified as T

import Tricorder.Build (Diagnostic (..), Severity (..))
import Tricorder.CLI.Render (diagnosticBlock)


test_Render :: TestTree
test_Render =
    testGroup
        "Render"
        [ testGroup
            "diagnosticBlock"
            [ testCase "includes the one-liner prefix for an error" do
                diagnosticBlock errMsg `shouldContainT` "E Foo.hs:10 type mismatch"
            , testCase "includes the full text body after the first line" do
                diagnosticBlock errMsg `shouldContainT` "\ntype mismatch"
            , testCase "uses 'W' prefix for warnings" do
                diagnosticBlock warnMsg `shouldContainT` "W Bar.hs:3 unused import"
            , testCase "contains both title and text when they differ" do
                let d = mixedMsg
                diagnosticBlock d `shouldContainT` "short title"
                diagnosticBlock d `shouldContainT` "full body of the message"
            ]
        ]
  where
    shouldContainT :: Text -> Text -> Assertion
    shouldContainT a b =
        assertBool (toString a <> "\ndoes not contain\n" <> toString b) $ b `T.isInfixOf` a


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

errMsg :: Diagnostic
errMsg =
    Diagnostic
        { severity = SError
        , file = "Foo.hs"
        , line = 10
        , col = 1
        , endLine = 10
        , endCol = 5
        , title = "type mismatch"
        , text = "type mismatch"
        }


warnMsg :: Diagnostic
warnMsg =
    Diagnostic
        { severity = SWarning
        , file = "Bar.hs"
        , line = 3
        , col = 1
        , endLine = 3
        , endCol = 10
        , title = "unused import"
        , text = "unused import"
        }


mixedMsg :: Diagnostic
mixedMsg =
    Diagnostic
        { severity = SError
        , file = "Baz.hs"
        , line = 5
        , col = 1
        , endLine = 5
        , endCol = 20
        , title = "short title"
        , text = "full body of the message"
        }
