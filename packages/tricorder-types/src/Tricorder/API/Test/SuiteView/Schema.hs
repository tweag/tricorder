module Tricorder.API.Test.SuiteView.Schema (defaultFields, schema) where

import Autodocodec (HasCodec (..))

import Tricorder.API.FieldMask (FieldMask (..))
import Tricorder.API.Test.SuiteView (SuiteView)

import Tricorder.API.FieldMask qualified as FieldMask
import Tricorder.API.FieldMask.Schema qualified as FieldMask (Schema)
import Tricorder.API.FieldMask.Schema qualified as FieldMask.Schema


schema :: FieldMask.Schema
schema = FieldMask.Schema.fromCodec $ codec @SuiteView


-- | A summary of each suite, leaving out the (potentially large) test output
-- and test cases.
defaultFields :: FieldMask
defaultFields =
    FieldMask
        $ (\name -> FieldMask.Field name Nothing)
            <$> "name" :| ["status", "error", "passed_cases", "total_cases", "duration_ms"]
