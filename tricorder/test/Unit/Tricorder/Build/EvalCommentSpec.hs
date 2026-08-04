module Unit.Tricorder.Build.EvalCommentSpec (spec_EvalComment) where

import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList, shouldSatisfy)
import Text.Megaparsec (parse)

import Tricorder.Build.EvalComment qualified as Eval


spec_EvalComment :: Spec
spec_EvalComment = do
    describe "singleLineEvalCommentP" testSingleLine
    describe "multiLineEvalCommentP" testMultiLine
    describe "blockCommentEvalP" testBlockComment
    describe "findComments" testFindComments


--------------------------------------------------------------------------------
-- singleLineEvalCommentP
--------------------------------------------------------------------------------

testSingleLine :: Spec
testSingleLine = do
    it "parses a basic expression" do
        parse Eval.singleLineEvalCommentP "" "-- $> 1 + 2"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "1 + 2"}

    it "handles no space between marker and expression" do
        parse Eval.singleLineEvalCommentP "" "-- $>expr"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "expr"}

    it "strips leading whitespace from the expression" do
        parse Eval.singleLineEvalCommentP "" "-- $>   expr"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "expr"}

    it "captures the full expression including inner spaces" do
        parse Eval.singleLineEvalCommentP "" "-- $> foo bar baz"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "foo bar baz"}

    it "stops at a newline, not consuming it" do
        parse Eval.singleLineEvalCommentP "" "-- $> expr\nnext line"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "expr"}

    it "fails when there is no expression after the marker" do
        parse Eval.singleLineEvalCommentP "" "-- $>" `shouldSatisfy` isLeft

    it "fails on the multi-line opening marker" do
        parse Eval.singleLineEvalCommentP "" "-- $$> expr -- <$$" `shouldSatisfy` isLeft

    it "fails on other text between comment start and eval marker" do
        parse Eval.singleLineEvalCommentP "" "-- foo $> 1 + 2" `shouldSatisfy` isLeft

    it "fails on unrelated text" do
        parse Eval.singleLineEvalCommentP "" "hello world" `shouldSatisfy` isLeft


--------------------------------------------------------------------------------
-- multiLineEvalCommentP
--------------------------------------------------------------------------------

testMultiLine :: Spec
testMultiLine = do
    it "parses a single content line, stripping the -- prefix" do
        parse Eval.multiLineEvalCommentP "" "-- $$>\n-- expr\n-- <$$"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "expr"}

    it "parses multiple content lines, stripping -- prefixes" do
        parse Eval.multiLineEvalCommentP "" "-- $$>\n-- foo\n-- bar\n-- <$$"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "foo\nbar"}

    it "preserves relative indentation after stripping -- prefix" do
        parse Eval.multiLineEvalCommentP "" "-- $$>\n-- let x = 1\n--     y = 2\n-- in x + y\n-- <$$"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "let x = 1\n    y = 2\nin x + y"}

    it "handles -- with no trailing space" do
        parse Eval.multiLineEvalCommentP "" "-- $$>\n--expr\n-- <$$"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "expr"}

    it "parse multi-line eval comment in a single line" do
        parse Eval.multiLineEvalCommentP "" "-- $$> expr <$$"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "expr"}

    it "fails when the closing marker is absent" do
        parse Eval.multiLineEvalCommentP "" "-- $$>\n-- expr" `shouldSatisfy` isLeft

    it "fails on the single-line marker" do
        parse Eval.multiLineEvalCommentP "" "-- $> expr" `shouldSatisfy` isLeft

    it "fails on unrelated text" do
        parse Eval.multiLineEvalCommentP "" "hello world" `shouldSatisfy` isLeft


--------------------------------------------------------------------------------
-- blockCommentEvalP
--------------------------------------------------------------------------------

testBlockComment :: Spec
testBlockComment = do
    it "parses a single-line expression on its own line" do
        parse Eval.blockCommentEvalP "" "{- $$>\n2 + 2\n<$$ -}"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "2 + 2"}

    it "parses an inline one-liner" do
        parse Eval.blockCommentEvalP "" "{- $$> 2 + 2 <$$ -}"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "2 + 2"}

    it "parses a multi-line expression preserving layout" do
        parse Eval.blockCommentEvalP "" "{- $$>\nlet x = 1\n    y = 2\nin x + y\n<$$ -}"
            `shouldBe` Right Eval.Comment {lineNumber = 1, expression = "let x = 1\n    y = 2\nin x + y"}

    it "fails when the closing marker is absent" do
        parse Eval.blockCommentEvalP "" "{- $$>\nexpr" `shouldSatisfy` isLeft

    it "fails on the line-comment multi-line eval marker" do
        parse Eval.blockCommentEvalP "" "-- $$> expr" `shouldSatisfy` isLeft

    it "fails on the single-line eval marker" do
        parse Eval.blockCommentEvalP "" "{- $> expr -}" `shouldSatisfy` isLeft

    it "fails on unrelated text" do
        parse Eval.blockCommentEvalP "" "hello world" `shouldSatisfy` isLeft


--------------------------------------------------------------------------------
-- findComments
--------------------------------------------------------------------------------

testFindComments :: Spec
testFindComments = do
    it "returns empty list for empty text" do
        Eval.findComments "" `shouldMatchList` []

    it "returns empty list when there are no eval comments" do
        Eval.findComments "hello world\nno comments here" `shouldMatchList` []

    it "finds a single single-line eval comment" do
        Eval.findComments "x = 1\n-- $> x\ny = 2"
            `shouldMatchList` [Eval.Comment {lineNumber = 2, expression = "x"}]

    it "finds multiple single-line eval comments in source order" do
        Eval.findComments "-- $> a\n-- $> b"
            `shouldMatchList` [ Eval.Comment {lineNumber = 1, expression = "a"}
                              , Eval.Comment {lineNumber = 2, expression = "b"}
                              ]

    it "reports correct line numbers" do
        Eval.findComments "line1\nline2\n-- $> expr\nline4"
            `shouldMatchList` [Eval.Comment {lineNumber = 3, expression = "expr"}]

    it "ignores lines that look like partial markers" do
        Eval.findComments "-- $\n-- $> expr"
            `shouldMatchList` [Eval.Comment {lineNumber = 2, expression = "expr"}]

    it "does not match an eval marker embedded in another comment" do
        Eval.findComments "-- foo -- $> expr" `shouldMatchList` []

    it "does not match an inline eval marker appearing after code" do
        Eval.findComments "x = 1  -- $> x" `shouldMatchList` []

    it "finds a multi-line eval comment, stripping -- prefixes" do
        Eval.findComments "-- $$>\n-- expr\n-- <$$"
            `shouldMatchList` [Eval.Comment {lineNumber = 1, expression = "expr"}]

    it "finds a block comment eval" do
        Eval.findComments "{- $$>\nexpr\n<$$ -}"
            `shouldMatchList` [Eval.Comment {lineNumber = 1, expression = "expr"}]

    it "finds both single-line and multi-line eval comments" do
        Eval.findComments "-- $> a\n-- $$>\n-- b\n-- <$$"
            `shouldMatchList` [ Eval.Comment {lineNumber = 1, expression = "a"}
                              , Eval.Comment {lineNumber = 2, expression = "b"}
                              ]

    it "finds both single-line and block comment eval comments" do
        Eval.findComments "-- $> a\n{- $$>\nb\n<$$ -}"
            `shouldMatchList` [ Eval.Comment {lineNumber = 1, expression = "a"}
                              , Eval.Comment {lineNumber = 2, expression = "b"}
                              ]
