module Tricorder.Runtime.PidFile
    ( PidFile (..)
    , asReader
    )
where

import Atelier.Effects.Posix.Daemons (PidFile (..))
import Effectful.Reader.Static (Reader)

import Tricorder.Runtime.Directory qualified as Runtime (Directory)
import Tricorder.Runtime.Directory qualified as Runtime.Directory


asReader :: (Reader Runtime.Directory :> es) => Eff (Reader PidFile : es) a -> Eff es a
asReader = Runtime.Directory.asReaderFor "daemon.pid" PidFile
