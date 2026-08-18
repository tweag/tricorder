module Tricorder.SourceLookup.Hackage
    ( Hackage (..)
    , Result (..)
    , fetchPackage
    , run
    )
where

import Atelier.Effects.Log (Log)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Exception (catch)
import Effectful.TH (makeEffect)
import Network.HTTP.Req
    ( GET (..)
    , HttpException
    , NoReqBody (..)
    , Scheme (..)
    , Url
    , bsResponse
    , defaultHttpConfig
    , https
    , renderUrl
    , req
    , responseBody
    , responseStatusCode
    , responseStatusMessage
    , runReq
    , (/:)
    )

import Atelier.Effects.Log qualified as Log

import Tricorder.Module (PackageId, unPackageId)


data Hackage :: Effect where
    FetchPackage :: PackageId -> Hackage m Result


data Result
    = NotFound
    | Failure Text
    | Success ByteString


makeEffect ''Hackage


run :: (IOE :> es, Log :> es) => Eff (Hackage : es) a -> Eff es a
run = interpret_ \case
    FetchPackage packageId -> do
        let url = packageUrl packageId
        Log.debug $ "Fetching sdist from " <> renderUrl url
        result <-
            flip catch (pure . Left @HttpException) . fmap Right
                $ liftIO
                $ runReq defaultHttpConfig
                $ req
                    GET
                    (url)
                    NoReqBody
                    bsResponse
                    mempty
        case result of
            Left ex -> do
                pure
                    $ Failure
                    $ "Failed to fetch "
                        <> unPackageId packageId
                        <> " from "
                        <> show url
                        <> "\n"
                        <> show ex
            Right response -> do
                let statusCode = responseStatusCode response
                if
                    | statusCode >= 200 && statusCode < 300 ->
                        pure $ Success $ responseBody response
                    | statusCode == 404 ->
                        pure NotFound
                    | otherwise -> do
                        pure $ Failure $ show (responseStatusCode response) <> ": " <> decodeUtf8 (responseStatusMessage response)


packageUrl :: PackageId -> Url 'Https
packageUrl packageId =
    https "hackage.haskell.org"
        /: "package"
        /: unPackageId packageId
        /: unPackageId packageId <> ".tar.gz"
