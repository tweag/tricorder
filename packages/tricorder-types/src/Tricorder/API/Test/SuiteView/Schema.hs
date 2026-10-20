module Tricorder.API.Test.SuiteView.Schema (defaultFields, schema) where

import Tricorder.API.FieldMask (FieldMask (..))

import Tricorder.API.FieldMask qualified as FieldMask
import Tricorder.API.FieldMask.Schema qualified as FieldMask (Schema (..))
import Tricorder.API.FieldMask.Schema qualified as FieldMask.Schema


-- | Every field of a 'SuiteView', as named in its JSON encoding.
schema :: FieldMask.Schema
schema =
    FieldMask.Schema
        [ FieldMask.Schema.leaf "name"
        , FieldMask.Schema.leaf "status"
        , FieldMask.Schema.leaf "error"
        , FieldMask.Schema.leaf "passed_cases"
        , FieldMask.Schema.leaf "total_cases"
        , FieldMask.Schema.leaf "duration_ms"
        , FieldMask.Schema.leaf "output"
        , FieldMask.Schema.nested
            "cases"
            [ FieldMask.Schema.leaf "description"
            , FieldMask.Schema.leaf "outcome"
            , FieldMask.Schema.leaf "failure"
            ]
        ]


-- | A summary of each suite, leaving out the (potentially large) test output
-- and test cases.
defaultFields :: FieldMask
defaultFields =
    FieldMask
        $ (\name -> FieldMask.Field name Nothing)
            <$> "name" :| ["status", "error", "passed_cases", "total_cases", "duration_ms"]
