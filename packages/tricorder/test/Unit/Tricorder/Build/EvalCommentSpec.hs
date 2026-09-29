module Unit.Tricorder.Build.EvalCommentSpec (test_EvalComment) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))
import Text.Megaparsec (parse)

import Tricorder.Build.EvalComment qualified as Eval


test_EvalComment :: TestTree
test_EvalComment =
    testGroup
        "EvalComment"
        [ testGroup "singleLineEvalCommentP" testSingleLine
        , testGroup "multiLineEvalCommentP" testMultiLine
        , testGroup "blockCommentEvalP" testBlockComment
        , testGroup "findComments" testFindComments
        ]


--------------------------------------------------------------------------------
-- singleLineEvalCommentP
--------------------------------------------------------------------------------

testSingleLine :: [TestTree]
testSingleLine =
    [ testCase "parses a basic expression" do
        parse Eval.singleLineEvalCommentP "" "-- $> 1 + 2"
            @?= Right Eval.Comment {lineNumber = 1, expression = "1 + 2"}
    , testCase "handles no space between marker and expression" do
        parse Eval.singleLineEvalCommentP "" "-- $>expr"
            @?= Right Eval.Comment {lineNumber = 1, expression = "expr"}
    , testCase "strips leading whitespace from the expression" do
        parse Eval.singleLineEvalCommentP "" "-- $>   expr"
            @?= Right Eval.Comment {lineNumber = 1, expression = "expr"}
    , testCase "captures the full expression including inner spaces" do
        parse Eval.singleLineEvalCommentP "" "-- $> foo bar baz"
            @?= Right Eval.Comment {lineNumber = 1, expression = "foo bar baz"}
    , testCase "stops at a newline, not consuming it" do
        parse Eval.singleLineEvalCommentP "" "-- $> expr\nnext line"
            @?= Right Eval.Comment {lineNumber = 1, expression = "expr"}
    , testCase "fails when there is no expression after the marker" do
        assertBool "expected Left" $ isLeft (parse Eval.singleLineEvalCommentP "" "-- $>")
    , testCase "fails on the multi-line opening marker" do
        assertBool "expected Left" $ isLeft (parse Eval.singleLineEvalCommentP "" "-- $$> expr -- <$$")
    , testCase "fails on other text between comment start and eval marker" do
        assertBool "expected Left" $ isLeft (parse Eval.singleLineEvalCommentP "" "-- foo $> 1 + 2")
    , testCase "fails on unrelated text" do
        assertBool "expected Left" $ isLeft (parse Eval.singleLineEvalCommentP "" "hello world")
    ]


--------------------------------------------------------------------------------
-- multiLineEvalCommentP
--------------------------------------------------------------------------------

testMultiLine :: [TestTree]
testMultiLine =
    [ testCase "parses a single content line, stripping the -- prefix" do
        parse Eval.multiLineEvalCommentP "" "-- $$>\n-- expr\n-- <$$"
            @?= Right Eval.Comment {lineNumber = 1, expression = "expr"}
    , testCase "parses multiple content lines, stripping -- prefixes" do
        parse Eval.multiLineEvalCommentP "" "-- $$>\n-- foo\n-- bar\n-- <$$"
            @?= Right Eval.Comment {lineNumber = 1, expression = "foo\nbar"}
    , testCase "preserves relative indentation after stripping -- prefix" do
        parse Eval.multiLineEvalCommentP "" "-- $$>\n-- let x = 1\n--     y = 2\n-- in x + y\n-- <$$"
            @?= Right Eval.Comment {lineNumber = 1, expression = "let x = 1\n    y = 2\nin x + y"}
    , testCase "handles -- with no trailing space" do
        parse Eval.multiLineEvalCommentP "" "-- $$>\n--expr\n-- <$$"
            @?= Right Eval.Comment {lineNumber = 1, expression = "expr"}
    , testCase "parse multi-line eval comment in a single line" do
        parse Eval.multiLineEvalCommentP "" "-- $$> expr <$$"
            @?= Right Eval.Comment {lineNumber = 1, expression = "expr"}
    , testCase "fails when the closing marker is absent" do
        assertBool "expected Left" $ isLeft (parse Eval.multiLineEvalCommentP "" "-- $$>\n-- expr")
    , testCase "fails on the single-line marker" do
        assertBool "expected Left" $ isLeft (parse Eval.multiLineEvalCommentP "" "-- $> expr")
    , testCase "fails on unrelated text" do
        assertBool "expected Left" $ isLeft (parse Eval.multiLineEvalCommentP "" "hello world")
    ]


--------------------------------------------------------------------------------
-- blockCommentEvalP
--------------------------------------------------------------------------------

testBlockComment :: [TestTree]
testBlockComment =
    [ testCase "parses a single-line expression on its own line" do
        parse Eval.blockCommentEvalP "" "{- $$>\n2 + 2\n<$$ -}"
            @?= Right Eval.Comment {lineNumber = 1, expression = "2 + 2"}
    , testCase "parses an inline one-liner" do
        parse Eval.blockCommentEvalP "" "{- $$> 2 + 2 <$$ -}"
            @?= Right Eval.Comment {lineNumber = 1, expression = "2 + 2"}
    , testCase "parses a multi-line expression preserving layout" do
        parse Eval.blockCommentEvalP "" "{- $$>\nlet x = 1\n    y = 2\nin x + y\n<$$ -}"
            @?= Right Eval.Comment {lineNumber = 1, expression = "let x = 1\n    y = 2\nin x + y"}
    , testCase "fails when the closing marker is absent" do
        assertBool "expected Left" $ isLeft (parse Eval.blockCommentEvalP "" "{- $$>\nexpr")
    , testCase "fails on the line-comment multi-line eval marker" do
        assertBool "expected Left" $ isLeft (parse Eval.blockCommentEvalP "" "-- $$> expr")
    , testCase "fails on the single-line eval marker" do
        assertBool "expected Left" $ isLeft (parse Eval.blockCommentEvalP "" "{- $> expr -}")
    , testCase "fails on unrelated text" do
        assertBool "expected Left" $ isLeft (parse Eval.blockCommentEvalP "" "hello world")
    ]


--------------------------------------------------------------------------------
-- findComments
--------------------------------------------------------------------------------

testFindComments :: [TestTree]
testFindComments =
    [ testCase "returns empty list for empty text" do
        Eval.findComments "" @?= []
    , testCase "returns empty list when there are no eval comments" do
        Eval.findComments "hello world\nno comments here" @?= []
    , testCase "finds a single single-line eval comment" do
        Eval.findComments "x = 1\n-- $> x\ny = 2"
            @?= [Eval.Comment {lineNumber = 2, expression = "x"}]
    , testCase "finds multiple single-line eval comments in source order" do
        Eval.findComments "-- $> a\n-- $> b"
            @?= [ Eval.Comment {lineNumber = 1, expression = "a"}
                , Eval.Comment {lineNumber = 2, expression = "b"}
                ]
    , testCase "reports correct line numbers" do
        Eval.findComments "line1\nline2\n-- $> expr\nline4"
            @?= [Eval.Comment {lineNumber = 3, expression = "expr"}]
    , testCase "ignores lines that look like partial markers" do
        Eval.findComments "-- $\n-- $> expr"
            @?= [Eval.Comment {lineNumber = 2, expression = "expr"}]
    , testCase "does not match an eval marker embedded in another comment" do
        Eval.findComments "-- foo -- $> expr" @?= []
    , testCase "does not match an inline eval marker appearing after code" do
        Eval.findComments "x = 1  -- $> x" @?= []
    , testCase "finds a multi-line eval comment, stripping -- prefixes" do
        Eval.findComments "-- $$>\n-- expr\n-- <$$"
            @?= [Eval.Comment {lineNumber = 1, expression = "expr"}]
    , testCase "finds a block comment eval" do
        Eval.findComments "{- $$>\nexpr\n<$$ -}"
            @?= [Eval.Comment {lineNumber = 1, expression = "expr"}]
    , testCase "finds both single-line and multi-line eval comments" do
        Eval.findComments "-- $> a\n-- $$>\n-- b\n-- <$$"
            @?= [ Eval.Comment {lineNumber = 1, expression = "a"}
                , Eval.Comment {lineNumber = 2, expression = "b"}
                ]
    , testCase "finds both single-line and block comment eval comments" do
        Eval.findComments "-- $> a\n{- $$>\nb\n<$$ -}"
            @?= [ Eval.Comment {lineNumber = 1, expression = "a"}
                , Eval.Comment {lineNumber = 2, expression = "b"}
                ]
    ]
