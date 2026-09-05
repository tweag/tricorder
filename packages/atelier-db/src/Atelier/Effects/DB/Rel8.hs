-- | Rel8 query helpers layered over the 'DBRead' and 'DBWrite' effects.
--
-- Thin wrappers that build Hasql @Statement@s from Rel8 queries and run them
-- through the database effects: 'select' and 'select1' for reads, and 'transact'
-- with 'insert_', 'update_', 'delete_' and 'selectTx' for writes. The Hasql
-- 'Transaction' type is re-exported for building transaction bodies.
module Atelier.Effects.DB.Rel8
    ( Transaction
    , select
    , select1
    , transact
    , insert_
    , update_
    , delete_
    , selectTx
    )
where

import Hasql.Transaction (Transaction)
import Rel8 (Delete, Insert, Query, Serializable, Update)

import Hasql.Transaction qualified as TX
import Rel8 qualified

import Atelier.Effects.DB (DBRead, DBWrite, runQuery, runTransaction)


-- | Run a Rel8 SELECT query via 'DBRead'.
select :: (DBRead :> es, Serializable exprs results) => Text -> Query exprs -> Eff es [results]
select name query = runQuery name (Rel8.run $ Rel8.select query)


-- | Run a Rel8 SELECT expecting exactly one result via 'DBRead'.
select1 :: (DBRead :> es, Serializable exprs results) => Text -> Query exprs -> Eff es results
select1 name query = runQuery name (Rel8.run1 $ Rel8.select query)


-- | Run a Hasql transaction via 'DBWrite'.
transact :: (DBWrite :> es) => Text -> Transaction a -> Eff es a
transact = runTransaction


-- | Run a Rel8 INSERT inside a 'Transaction'.
insert_ :: Insert a -> Transaction ()
insert_ = TX.statement () . Rel8.run_ . Rel8.insert


-- | Run a Rel8 UPDATE inside a 'Transaction'.
update_ :: Update a -> Transaction ()
update_ = TX.statement () . Rel8.run_ . Rel8.update


-- | Run a Rel8 DELETE inside a 'Transaction'.
delete_ :: Delete a -> Transaction ()
delete_ = TX.statement () . Rel8.run_ . Rel8.delete


-- | Run a Rel8 SELECT inside a 'Transaction'.
selectTx :: (Serializable exprs results) => Query exprs -> Transaction [results]
selectTx = TX.statement () . Rel8.run . Rel8.select
