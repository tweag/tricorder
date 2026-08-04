module Tricorder.CLI.Render
    ( -- * Plain-text formatting
      diagnosticLine
    , diagnosticLineIndexed
    , diagnosticBlock
    , formatDuration
    , renderSourceResults
    ) where

import Atelier.Effects.Console (Console)
import Atelier.Time (Millisecond, toMicroseconds)

import Atelier.Effects.Console qualified as Console

import Tricorder.Build (Diagnostic (..), Severity (..))
import Tricorder.Module (ModuleName (..), PackageId (..))
import Tricorder.SourceLookup (ModuleSourceResult (..), SourceQuery (..))


formatDuration :: Millisecond -> Text
formatDuration d =
    let ms = toMicroseconds d `div` 1000
    in  if ms < 1000 then
            show ms <> "ms"
        else
            show (ms `div` 1000) <> "." <> show ((ms `mod` 1000) `div` 100) <> "s"


-- | Single-line diagnostic for plain-text / shell output.
--
-- Format: @E src\/Foo\/Bar.hs:42 \`something\` not in scope@
diagnosticLine :: Diagnostic -> Text
diagnosticLine d =
    prefix d.severity <> " " <> toText d.file <> ":" <> show d.line <> " " <> d.title
  where
    prefix SError = "E"
    prefix SWarning = "W"


-- | Like 'diagnosticLine' but prefixed with a 1-based index.
--
-- Format: @[N] E src\/Foo\/Bar.hs:42 \`something\` not in scope@
diagnosticLineIndexed :: Int -> Diagnostic -> Text
diagnosticLineIndexed n d = "[" <> show n <> "] " <> diagnosticLine d


-- | One-liner followed by the full GHC message body (verbose mode).
diagnosticBlock :: Diagnostic -> Text
diagnosticBlock d = diagnosticLine d <> "\n" <> d.text


renderSourceResults :: (Console :> es) => [ModuleSourceResult] -> Eff es ()
renderSourceResults results = mapM_ renderOne results
  where
    renderOne (SourceFound query src) = do
        when (length results > 1) $ Console.putTextLn $ header query
        Console.putText src
        when (length results > 1) $ Console.putStrLn ""
    renderOne (SourceNotFound query) =
        Console.putTextLn
            $ "Not found: "
                <> unModuleName query.moduleName
                <> " (module not in any installed package)"
    renderOne (SourceUnavailable query pkgId) =
        Console.putTextLn
            $ "No source available: "
                <> unModuleName query.moduleName
                <> " (could not locate or fetch a source tarball for "
                <> unPackageId pkgId
                <> ")"
    renderOne (FunctionNotFound query) =
        Console.putTextLn
            $ "tricorder: "
                <> unModuleName query.moduleName
                <> "#"
                <> fromMaybe "" query.function
                <> ": function not found in module source"

    header query =
        "-- "
            <> unModuleName query.moduleName
            <> maybe "" ("#" <>) query.function
