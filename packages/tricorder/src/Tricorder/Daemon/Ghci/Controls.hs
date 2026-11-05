module Tricorder.Daemon.Ghci.Controls
    ( Controls (..)
    , lift
    )
where

import Atelier.FileSystem.Path qualified as Path

import Tricorder.Daemon.Ghci.LoadResult (LoadResult)


data Controls m = Controls
    { reload :: m LoadResult
    , interrupt :: m ()
    , add :: Path.Any -> m LoadResult
    , unadd :: Text -> m LoadResult
    }


lift :: (forall a. m a -> n a) -> Controls m -> Controls n
lift f ctrls =
    Controls
        { reload = f ctrls.reload
        , interrupt = f ctrls.interrupt
        , add = f . ctrls.add
        , unadd = f . ctrls.unadd
        }
