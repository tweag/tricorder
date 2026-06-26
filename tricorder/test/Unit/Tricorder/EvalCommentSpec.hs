module Unit.Tricorder.EvalCommentSpec (spec_EvalComment) where

import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList, shouldSatisfy)
import Text.Megaparsec (parse)

import Tricorder.EvalComment
    ( EvalComment (..)
    , blockCommentEvalP
    , findEvalComments
    , multiLineEvalCommentP
    , singleLineEvalCommentP
    )


spec_EvalComment :: Spec
spec_EvalComment = do
    describe "singleLineEvalCommentP" testSingleLine
    describe "multiLineEvalCommentP" testMultiLine
    describe "blockCommentEvalP" testBlockComment
    describe "findEvalComments" testFindEvalComments


--------------------------------------------------------------------------------
-- singleLineEvalCommentP
--------------------------------------------------------------------------------

testSingleLine :: Spec
testSingleLine = do
    it "parses a basic expression" do
        parse singleLineEvalCommentP "" "-- $> 1 + 2"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "1 + 2"}

    it "handles no space between marker and expression" do
        parse singleLineEvalCommentP "" "-- $>expr"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "expr"}

    it "strips leading whitespace from the expression" do
        parse singleLineEvalCommentP "" "-- $>   expr"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "expr"}

    it "captures the full expression including inner spaces" do
        parse singleLineEvalCommentP "" "-- $> foo bar baz"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "foo bar baz"}

    it "stops at a newline, not consuming it" do
        parse singleLineEvalCommentP "" "-- $> expr\nnext line"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "expr"}

    it "fails when there is no expression after the marker" do
        parse singleLineEvalCommentP "" "-- $>" `shouldSatisfy` isLeft

    it "fails on the multi-line opening marker" do
        parse singleLineEvalCommentP "" "-- $$> expr -- <$$" `shouldSatisfy` isLeft

    it "fails on other text between comment start and eval marker" do
        parse singleLineEvalCommentP "" "-- foo $> 1 + 2" `shouldSatisfy` isLeft

    it "fails on unrelated text" do
        parse singleLineEvalCommentP "" "hello world" `shouldSatisfy` isLeft


--------------------------------------------------------------------------------
-- multiLineEvalCommentP
--------------------------------------------------------------------------------

testMultiLine :: Spec
testMultiLine = do
    it "parses a single content line, stripping the -- prefix" do
        parse multiLineEvalCommentP "" "-- $$>\n-- expr\n-- <$$"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "expr"}

    it "parses multiple content lines, stripping -- prefixes" do
        parse multiLineEvalCommentP "" "-- $$>\n-- foo\n-- bar\n-- <$$"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "foo\nbar"}

    it "preserves relative indentation after stripping -- prefix" do
        parse multiLineEvalCommentP "" "-- $$>\n-- let x = 1\n--     y = 2\n-- in x + y\n-- <$$"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "let x = 1\n    y = 2\nin x + y"}

    it "handles -- with no trailing space" do
        parse multiLineEvalCommentP "" "-- $$>\n--expr\n-- <$$"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "expr"}

    it "parse multi-line eval comment in a single line" do
        parse multiLineEvalCommentP "" "-- $$> expr <$$"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "expr"}

    it "fails when the closing marker is absent" do
        parse multiLineEvalCommentP "" "-- $$>\n-- expr" `shouldSatisfy` isLeft

    it "fails on the single-line marker" do
        parse multiLineEvalCommentP "" "-- $> expr" `shouldSatisfy` isLeft

    it "fails on unrelated text" do
        parse multiLineEvalCommentP "" "hello world" `shouldSatisfy` isLeft


--------------------------------------------------------------------------------
-- blockCommentEvalP
--------------------------------------------------------------------------------

testBlockComment :: Spec
testBlockComment = do
    it "parses a single-line expression on its own line" do
        parse blockCommentEvalP "" "{- $$>\n2 + 2\n<$$ -}"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "2 + 2"}

    it "parses an inline one-liner" do
        parse blockCommentEvalP "" "{- $$> 2 + 2 <$$ -}"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "2 + 2"}

    it "parses a multi-line expression preserving layout" do
        parse blockCommentEvalP "" "{- $$>\nlet x = 1\n    y = 2\nin x + y\n<$$ -}"
            `shouldBe` Right EvalComment {lineNumber = 1, expression = "let x = 1\n    y = 2\nin x + y"}

    it "fails when the closing marker is absent" do
        parse blockCommentEvalP "" "{- $$>\nexpr" `shouldSatisfy` isLeft

    it "fails on the line-comment multi-line eval marker" do
        parse blockCommentEvalP "" "-- $$> expr" `shouldSatisfy` isLeft

    it "fails on the single-line eval marker" do
        parse blockCommentEvalP "" "{- $> expr -}" `shouldSatisfy` isLeft

    it "fails on unrelated text" do
        parse blockCommentEvalP "" "hello world" `shouldSatisfy` isLeft


--------------------------------------------------------------------------------
-- findEvalComments
--------------------------------------------------------------------------------

testFindEvalComments :: Spec
testFindEvalComments = do
    it "returns empty list for empty text" do
        findEvalComments "" `shouldMatchList` []

    it "returns empty list when there are no eval comments" do
        findEvalComments "hello world\nno comments here" `shouldMatchList` []

    it "finds a single single-line eval comment" do
        findEvalComments "x = 1\n-- $> x\ny = 2"
            `shouldMatchList` [EvalComment {lineNumber = 2, expression = "x"}]

    it "finds multiple single-line eval comments in source order" do
        findEvalComments "-- $> a\n-- $> b"
            `shouldMatchList` [ EvalComment {lineNumber = 1, expression = "a"}
                              , EvalComment {lineNumber = 2, expression = "b"}
                              ]

    it "reports correct line numbers" do
        findEvalComments "line1\nline2\n-- $> expr\nline4"
            `shouldMatchList` [EvalComment {lineNumber = 3, expression = "expr"}]

    it "ignores lines that look like partial markers" do
        findEvalComments "-- $\n-- $> expr"
            `shouldMatchList` [EvalComment {lineNumber = 2, expression = "expr"}]

    it "does not match an eval marker embedded in another comment" do
        findEvalComments "-- foo -- $> expr" `shouldMatchList` []

    it "does not match an inline eval marker appearing after code" do
        findEvalComments "x = 1  -- $> x" `shouldMatchList` []

    it "finds a multi-line eval comment, stripping -- prefixes" do
        findEvalComments "-- $$>\n-- expr\n-- <$$"
            `shouldMatchList` [EvalComment {lineNumber = 1, expression = "expr"}]

    it "finds a block comment eval" do
        findEvalComments "{- $$>\nexpr\n<$$ -}"
            `shouldMatchList` [EvalComment {lineNumber = 1, expression = "expr"}]

    it "finds both single-line and multi-line eval comments" do
        findEvalComments "-- $> a\n-- $$>\n-- b\n-- <$$"
            `shouldMatchList` [ EvalComment {lineNumber = 1, expression = "a"}
                              , EvalComment {lineNumber = 2, expression = "b"}
                              ]

    it "finds both single-line and block comment eval comments" do
        findEvalComments "-- $> a\n{- $$>\nb\n<$$ -}"
            `shouldMatchList` [ EvalComment {lineNumber = 1, expression = "a"}
                              , EvalComment {lineNumber = 2, expression = "b"}
                              ]
