module Unit.Atelier.Effects.LogSpec (test_Log) where

import Effectful (runPureEff)
import Effectful.Writer.Static.Shared (Writer, execWriter)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.Log (Log, Message (..), info, runLogWriter, withNamespace)


runLogTest :: Eff [Log, Writer [Message]] a -> [Message]
runLogTest =
    runPureEff
        . execWriter @[Message]
        . runLogWriter


test_Log :: TestTree
test_Log =
    testGroup
        "Log"
        [ testGroup
            "Log with namespace"
            [ testCase "logs without namespace when not provided" $ do
                let logs =
                        fmap (\m -> (m.namespace, m.text))
                            . runLogTest
                            $ info "test message"
                logs @?= [("", "test message")]
            , testCase "prepends a namespace to the logged message" $ do
                let logs =
                        fmap (\m -> (m.namespace, m.text))
                            . runLogTest
                            . withNamespace "component"
                            $ info "test message"
                logs @?= [("component", "test message")]
            , testGroup
                "nested namespaces"
                [ testCase "appends a namespace to the current namespace" $ do
                    let logs =
                            fmap (\m -> (m.namespace, m.text))
                                . runLogTest
                                . withNamespace "parent"
                                . withNamespace "child"
                                $ info "test message"
                    logs @?= [("parent.child", "test message")]
                , testCase "handles multiple levels of nesting" $ do
                    let logs =
                            fmap (\m -> (m.namespace, m.text))
                                . runLogTest
                                . withNamespace "level1"
                                . withNamespace "level2"
                                . withNamespace "level3"
                                $ info "test message"
                    logs @?= [("level1.level2.level3", "test message")]
                ]
            , testGroup
                "namespace scoping"
                [ testCase "only applies namespace within its scope" $ do
                    let logs =
                            fmap (\m -> (m.namespace, m.text))
                                . runPureEff
                                . execWriter @[Message]
                                . runLogWriter
                                $ do
                                    info "before"
                                    withNamespace "scoped" $ info "inside"
                                    info "after"
                    logs
                        @?= [ ("", "before")
                            , ("scoped", "inside")
                            , ("", "after")
                            ]
                , testCase "handles partially nested scopes" $ do
                    let logs =
                            fmap (\m -> (m.namespace, m.text))
                                . runPureEff
                                . execWriter @[Message]
                                . runLogWriter
                                . withNamespace "outer"
                                $ do
                                    info "outer msg"
                                    withNamespace "inner" $ info "inner msg"
                                    info "outer again"
                    logs
                        @?= [ ("outer", "outer msg")
                            , ("outer.inner", "inner msg")
                            , ("outer", "outer again")
                            ]
                ]
            ]
        ]
