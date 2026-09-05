module Unit.Atelier.Effects.LogSpec (spec_Log) where

import Effectful (runPureEff)
import Effectful.Writer.Static.Shared (Writer, execWriter)
import Test.Hspec (Spec, describe, it, shouldBe)

import Atelier.Effects.Log (Log, Message (..), info, runLogWriter, withNamespace)


runLogTest :: Eff [Log, Writer [Message]] a -> [Message]
runLogTest =
    runPureEff
        . execWriter @[Message]
        . runLogWriter


spec_Log :: Spec
spec_Log = do
    describe "Log with namespace" $ do
        it "logs without namespace when not provided" $ do
            let logs =
                    fmap (\m -> (m.namespace, m.text))
                        . runLogTest
                        $ info "test message"
            logs `shouldBe` [("", "test message")]

        it "prepends a namespace to the logged message" $ do
            let logs =
                    fmap (\m -> (m.namespace, m.text))
                        . runLogTest
                        . withNamespace "component"
                        $ info "test message"
            logs `shouldBe` [("component", "test message")]

        describe "nested namespaces" $ do
            it "appends a namespace to the current namespace" $ do
                let logs =
                        fmap (\m -> (m.namespace, m.text))
                            . runLogTest
                            . withNamespace "parent"
                            . withNamespace "child"
                            $ info "test message"
                logs `shouldBe` [("parent.child", "test message")]

            it "handles multiple levels of nesting" $ do
                let logs =
                        fmap (\m -> (m.namespace, m.text))
                            . runLogTest
                            . withNamespace "level1"
                            . withNamespace "level2"
                            . withNamespace "level3"
                            $ info "test message"
                logs `shouldBe` [("level1.level2.level3", "test message")]

        describe "namespace scoping" $ do
            it "only applies namespace within its scope" $ do
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
                    `shouldBe` [ ("", "before")
                               , ("scoped", "inside")
                               , ("", "after")
                               ]

            it "handles partially nested scopes" $ do
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
                    `shouldBe` [ ("outer", "outer msg")
                               , ("outer.inner", "inner msg")
                               , ("outer", "outer again")
                               ]
