module Tricorder.Daemon.Ghci.Controls
    ( Controls (..)
    , lift
    )
where

import Tricorder.Daemon.Ghci.LoadResult (LoadResult)


data Controls m = Controls
    { reload :: m LoadResult
    , interrupt :: m ()
    , add :: FilePath -> m LoadResult
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
