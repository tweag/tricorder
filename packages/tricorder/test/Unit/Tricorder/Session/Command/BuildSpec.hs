module Unit.Tricorder.Session.Command.BuildSpec (test_Build) where

import Atelier.Effects.FileSystem (FileSystem, runFileSystemState)
import Data.Default (def)
import Effectful (runPureEff)
import Effectful.State.Static.Shared (State, evalState)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.Map.Strict qualified as Map

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Command.Build (renderBuild, resolveBuildCommand)
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetsPlaceholder)
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.Repl (Repl (..), resolveRepl)
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (Target, parseTarget)
import Tricorder.Session.TestTarget (TestTarget, parseTestTargets)

import Tricorder.Session.Config qualified as Config


test_Build :: TestTree
test_Build =
    testGroup
        "Build"
        [ testGroup "resolveBuildCommand" testResolveBuildCommand
        , testGroup "renderBuild" testRenderBuild
        ]


testRenderBuild :: [TestTree]
testRenderBuild =
    [ testCase "substitutes {targets} with the rendered target list" do
        build (CommandTemplate Cabal "cabal repl {targets}" [] targetsPlaceholder) [parseTarget "lib:foo"]
            @?= "cabal repl lib:foo"
    , testCase "substitutes every occurrence of {targets}" do
        build
            (CommandTemplate Cabal "echo {targets} && cabal repl {targets}" [] targetsPlaceholder)
            [parseTarget "lib:foo"]
            @?= "echo lib:foo && cabal repl lib:foo"
    , testCase "leaves a template with no placeholder untouched, but still appends arguments" do
        build
            (CommandTemplate Cabal "my-wrapper --repl" ["--flag"] targetsPlaceholder)
            [parseTarget "lib:foo"]
            @?= "my-wrapper --repl --flag"
    , testCase "renders \\{targets} as a literal {targets}, without substitution" do
        build (CommandTemplate Cabal "echo \\{targets}" [] targetsPlaceholder) [parseTarget "lib:foo"]
            @?= "echo {targets}"
    , testCase "substitutes an unescaped {targets} while leaving an escaped one literal" do
        build
            (CommandTemplate Cabal "echo \\{targets} && cabal repl {targets}" [] targetsPlaceholder)
            [parseTarget "lib:foo"]
            @?= "echo {targets} && cabal repl lib:foo"
    , testCase "substitutes {targets} with nothing when the target list is empty" do
        build (CommandTemplate Cabal "cabal repl {targets}" [] targetsPlaceholder) []
            @?= "cabal repl"
    , testCase "appends arguments after the rendered template" do
        build
            (CommandTemplate Cabal "cabal repl {targets}" ["--flag", "value"] targetsPlaceholder)
            [parseTarget "lib:foo"]
            @?= "cabal repl lib:foo --flag value"
    , testCase "does not substitute {target} (singular) when the command uses targetsPlaceholder" do
        build (CommandTemplate Cabal "cabal repl {target}" [] targetsPlaceholder) [parseTarget "lib:foo"]
            @?= "cabal repl {target}"
    ]
  where
    build template targets = (renderBuild template targets).getResolvedCommand


testResolveBuildCommand :: [TestTree]
testResolveBuildCommand =
    [ testGroup
        "deprecated top-level command"
        [ testCase "is used as the build template when build.command_template is unset" do
            renderBuildFor [] def {command = Just "foo"} [] sampleTestTargets @?= "foo"
        ]
    , testGroup
        "build.command_template"
        [ testCase "overrides the deprecated top-level command" do
            let cfg =
                    cfg0
                        { command = Just "should be ignored"
                        , build = cfg0.build {commandTemplate = Just "cabal repl {targets}"}
                        }
            renderBuildFor [("/cabal.project", "")] cfg (parseTarget <$> ["lib:foo"]) sampleTestTargets
                @?= "cabal repl lib:foo"
        ]
    , testGroup
        "explicit targets"
        [ testCase "spell them out verbatim, ignoring discovered test targets" do
            renderBuildFor [("/cabal.project", "")] cfg0 (parseTarget <$> ["lib:foo"]) sampleTestTargets
                @?= "cabal repl --enable-multi-repl --builddir /replbuild lib:foo"
        ]
    , testGroup
        "no command or targets configured"
        [ testGroup
            "and there is a cabal.project file"
            [ testCase "uses cabal 'all' plus the discovered test targets" do
                renderBuildFor [("/cabal.project", "")] cfg0 [] sampleTestTargets
                    @?= "cabal repl --enable-multi-repl --builddir /replbuild all test:foo"
            ]
        , testGroup
            "and there is at least one *.cabal file"
            [ testCase "uses cabal 'all' plus the discovered test targets" do
                renderBuildFor [("/foo.cabal", "")] cfg0 [] sampleTestTargets
                    @?= "cabal repl --enable-multi-repl --builddir /replbuild all test:foo"
            ]
        , testGroup
            "and there is a stack.yaml file"
            [ testCase "uses stack ghci with 'all' plus test targets" do
                renderBuildFor [("/stack.yaml", "")] cfg0 [] sampleTestTargets
                    @?= "stack ghci all foo"
            ]
        , testGroup
            "and there is both a stack.yaml and a cabal.project file"
            [ testCase "prefers stack ghci over cabal" do
                renderBuildFor [("/stack.yaml", ""), ("/cabal.project", "")] cfg0 [] sampleTestTargets
                    @?= "stack ghci all foo"
            ]
        , testGroup
            "but there are no project files"
            [ testCase "uses default cabal repl with 'all' plus test targets" do
                renderBuildFor [] cfg0 [] sampleTestTargets
                    @?= "cabal repl --builddir /replbuild all test:foo"
            ]
        , testGroup
            "and no test targets are discovered"
            [ testCase "falls back to plain 'all'" do
                renderBuildFor [("/cabal.project", "")] cfg0 [] (parseTestTargets [])
                    @?= "cabal repl --enable-multi-repl --builddir /replbuild all"
            ]
        ]
    , testGroup
        "build.extra_auto_arguments"
        [ testCase "is appended after the rendered automatically resolved template" do
            let cfg = cfg0 {build = cfg0.build {extraAutoArguments = ["--extra-flag"]}}
            renderBuildFor [("/cabal.project", "")] cfg (parseTarget <$> ["lib:foo"]) sampleTestTargets
                @?= "cabal repl --enable-multi-repl --builddir /replbuild lib:foo --extra-flag"
        , testCase "is ignored when build.command_template is set" do
            let cfg =
                    cfg0
                        { build =
                            cfg0.build
                                { commandTemplate = Just "cabal repl {targets}"
                                , extraAutoArguments = ["--extra-flag"]
                                }
                        }
            renderBuildFor [("/cabal.project", "")] cfg (parseTarget <$> ["lib:foo"]) sampleTestTargets
                @?= "cabal repl lib:foo"
        , testCase "is ignored when the deprecated top-level command is set" do
            let cfg =
                    cfg0
                        { command = Just "cabal repl {targets}"
                        , build = cfg0.build {extraAutoArguments = ["--extra-flag"]}
                        }
            renderBuildFor [("/cabal.project", "")] cfg (parseTarget <$> ["lib:foo"]) sampleTestTargets
                @?= "cabal repl lib:foo"
        ]
    ]


-- | Resolve and fully render the build command against a faked filesystem —
-- the composition 'Tricorder.Session.loadSession' and 'Tricorder.Daemon.Core'
-- perform between them (resolve a 'CommandTemplate' plus its target list,
-- then 'renderBuild' the two together).
renderBuildFor :: [(FilePath, ByteString)] -> Config -> [Target] -> [TestTarget] -> Text
renderBuildFor files cfg targets tts =
    (uncurry renderBuild $ withFiles files $ resolveBuild cfg targets tts).getResolvedCommand


-- | Run a 'FileSystem'-using computation against a faked in-memory
-- filesystem seeded with the given files (content is irrelevant except for
-- @stack.yaml@, which is parsed for its @packages@ key).
withFiles :: [(FilePath, ByteString)] -> Eff '[FileSystem, State (Map FilePath ByteString)] a -> a
withFiles files action =
    runPureEff $ evalState (Map.fromList files) $ runFileSystemState action


cfg0 :: Config
cfg0 = def {Config.replBuildDir = "/replbuild"}


sampleTestTargets :: [TestTarget]
sampleTestTargets = parseTestTargets ["test:foo"]


-- | Resolve 'Repl' from the faked filesystem, then resolve the build
-- command from it — mirrors how 'Tricorder.Session.loadSession' chains the
-- two steps.
resolveBuild
    :: (FileSystem :> es)
    => Config -> [Target] -> [TestTarget] -> Eff es (CommandTemplate 'Build, [Target])
resolveBuild cfg targets tts = do
    repl <- resolveRepl pr
    resolveBuildCommand pr cfg repl targets tts


pr :: ProjectRoot
pr = ProjectRoot "/"
