module Tricorder.Runtime.Directory
    ( Directory (..)
    , asReader
    , asReaderFor
    )
where

import Atelier.Effects.Env (Env)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.Log (Log)
import Atelier.FileSystem.Path ((</>))
import Effectful.Exception (trySync)
import Effectful.FileSystem (FileSystem)
import Effectful.NonDet (emptyEff, plusEff)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.Env qualified as Env
import Atelier.Effects.Exit qualified as Exit
import Atelier.Effects.Log qualified as Log
import Atelier.FileSystem.Directory qualified as Directory
import Atelier.FileSystem.Path qualified as Path
import Atelier.FileSystem.Permissions qualified as Permissions
import Effectful.NonDet qualified as NonDet
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.ProjectHash (ProjectHash (..))


newtype Directory = Directory {getDirectory :: Path.Absolute}


asReader
    :: ( Env :> es
       , Exit :> es
       , FileSystem :> es
       , Log :> es
       , Reader ProjectHash :> es
       )
    => Eff (Reader Directory : es) a -> Eff es a
asReader act = do
    ProjectHash projectDirHash <- Reader.ask
    let subDir = Path.relative @"tricorder" </> projectDirHash
        fallback = do
            res <- mkUsable $ Path.abs @"/tmp" </> subDir
            case res of
                Just d -> pure d
                Nothing -> do
                    Log.err
                        "Could not create a writable directory in XDG_RUNTIME_DIR, XDG_STATE_HOME nor int he temporary directory. Tricorder cannot contact the daemon without creating a socket file."
                    Exit.failure
    dir <-
        (either (const fallback) pure)
            <=< NonDet.runNonDet NonDet.OnEmptyKeep
            $ xdgRuntimeCandidate subDir
                `plusEff` xdgStateCandidate subDir
                `plusEff` temporaryCandidate subDir
    Reader.runReader (Directory dir) act
  where
    xdgRuntimeCandidate dir' = do
        runtimeDir <- Env.lookup "XDG_RUNTIME_DIR"
        case runtimeDir of
            Just d | Right path <- Path.fromFilePath d -> do
                usable <- mkUsable $ path </> dir'
                case usable of
                    Just valid -> pure valid
                    Nothing -> emptyEff
            _ -> emptyEff
    xdgStateCandidate dir' = do
        res <- trySync $ Directory.getXdg Directory.XdgState dir'
        case res of
            Right path -> do
                usable <- mkUsable path
                case usable of
                    Just valid -> pure valid
                    Nothing -> emptyEff
            Left _ -> emptyEff
    temporaryCandidate dir' = do
        res <- trySync Directory.getTemporary
        case res of
            Right path -> do
                usable <- mkUsable $ path </> dir'
                case usable of
                    Just valid -> pure valid
                    Nothing -> emptyEff
            Left _ -> emptyEff

    mkUsable dir = do
        r <- trySync do
            Directory.createIfMissing True dir
            Permissions.get dir
        case r of
            Right permissions | Permissions.writable permissions -> pure $ Just dir
            _ -> pure Nothing


asReaderFor
    :: (Reader Directory :> es)
    => Path.Relative
    -- ^ Path segment to append to runtime dir.
    -> (Path.Absolute -> a)
    -- ^ Constructor for the resulting type.
    -> Eff (Reader a : es) b
    -> Eff es b
asReaderFor path mk act = do
    Directory dir <- Reader.ask
    Reader.runReader (mk $ dir </> path) act
