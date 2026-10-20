module Unit.Tricorder.API.SuiteView.SchemaSpec (test_Schema) where

import Atelier.Time (AsRawUnit (..))
import Data.Aeson (Value (..), toJSON)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KeyMap

import Tricorder.API.Test.SuiteView (CaseView (..), Outcome (..), Status (..), SuiteView (..))
import Tricorder.API.Test.SuiteView.Schema (defaultFields, schema)

import Tricorder.API.FieldMask.Schema qualified as FieldMask (Schema (..))
import Tricorder.API.FieldMask.Schema qualified as FieldMask.Schema


test_Schema :: TestTree
test_Schema =
    testGroup
        "Tricorder.API.SuiteView.Schema"
        [ testCase "schema lists every field of the JSON encoding" do
            schemaKeys schema @?= jsonKeys (toJSON fullView)
        , testCase "default fields are in the schema" do
            void (FieldMask.Schema.select schema defaultFields) @?= Right ()
        ]


-- | Keys of a JSON value, nested keys of arrays taken from their first element.
data Keys = Keys [(Text, Maybe Keys)]
    deriving stock (Eq, Show)


schemaKeys :: FieldMask.Schema -> Keys
schemaKeys (FieldMask.Schema fields) = Keys $ sortOn fst $ second (fmap schemaKeys) <$> fields


jsonKeys :: Value -> Keys
jsonKeys = \case
    Object obj -> Keys $ sortOn fst [(Key.toText key, nestedKeys value) | (key, value) <- KeyMap.toList obj]
    _ -> Keys []
  where
    nestedKeys = \case
        Array values | Just element <- viaNonEmpty head (toList values) -> Just $ jsonKeys element
        _ -> Nothing


-- | A view with every field set, so every field shows up in its JSON.
fullView :: SuiteView
fullView =
    SuiteView
        { name = "test:suite"
        , status = Failed
        , error = Just "error"
        , passedCases = Just 0
        , totalCases = Just 1
        , durationMs = Just $ AsRawUnit 5
        , output = Just "output"
        , cases = Just [CaseView "case" CaseFailed (Just "failure")]
        }
