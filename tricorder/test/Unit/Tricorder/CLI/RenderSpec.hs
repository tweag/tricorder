module Unit.Tricorder.CLI.RenderSpec (spec_Render) where

import Test.Hspec

import Tricorder.Build (Diagnostic (..), Severity (..))
import Tricorder.CLI.Render (diagnosticBlock)


spec_Render :: Spec
spec_Render = do
    describe "diagnosticBlock" do
        it "includes the one-liner prefix for an error" do
            diagnosticBlock errMsg `shouldContainT` "E Foo.hs:10 type mismatch"

        it "includes the full text body after the first line" do
            diagnosticBlock errMsg `shouldContainT` "\ntype mismatch"

        it "uses 'W' prefix for warnings" do
            diagnosticBlock warnMsg `shouldContainT` "W Bar.hs:3 unused import"

        it "contains both title and text when they differ" do
            let d = mixedMsg
            diagnosticBlock d `shouldContainT` "short title"
            diagnosticBlock d `shouldContainT` "full body of the message"
  where
    shouldContainT :: Text -> Text -> Expectation
    shouldContainT a b = toString a `shouldContain` toString b


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
