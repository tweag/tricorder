-- | A checked wrapper around 'deriveToolHandlerWithOptions'.
--
-- @mcp-server@ looks up tool and field descriptions by name, so a missing,
-- misspelt or stale entry silently falls back to the bare constructor or field
-- name. 'deriveCheckedToolHandler' reifies the tool type and fails compilation
-- unless the descriptions cover exactly its constructors, and each
-- constructor's descriptions cover exactly its fields.
module Tricorder.MCP.Derive (deriveCheckedToolHandler) where

import Language.Haskell.TH (Con (..), Dec (..), Exp, Info (..), Name, Q, Type (..), nameBase, reify)
import MCP.Server.Derive (DefinitionOptions (..), deriveToolHandlerWithOptions)

import Data.List qualified as List


deriveCheckedToolHandler :: Name -> Name -> [(String, DefinitionOptions)] -> Q Exp
deriveCheckedToolHandler typeName handlerName opts = do
    cons <- reifyCons typeName
    conProblems <- concat <$> traverse checkCon cons
    let conNames = map (nameBase . conName) cons
        problems =
            conProblems
                <> mismatches "tool" (nameBase typeName) conNames (map fst opts)
    unless (null problems)
        $ fail
        $ List.unlines
        $ ("Tool descriptions are out of sync with " <> nameBase typeName <> ":")
            : map ("  - " <>) problems
    deriveToolHandlerWithOptions typeName handlerName opts
  where
    checkCon con = do
        let name = nameBase (conName con)
        fields <- conFieldNames con
        pure $ case List.lookup name opts of
            Nothing -> []
            Just o ->
                mismatches "field" name fields (map (toString . fst) (optFieldDescriptions o))


-- | Report entries missing from, or unknown to, the expected set of names.
mismatches :: String -> String -> [String] -> [String] -> [String]
mismatches kind owner expected described =
    [ "missing " <> kind <> " description for " <> owner <> "." <> n
    | n <- expected List.\\ described
    ]
        <> [ "description for unknown " <> kind <> " " <> owner <> "." <> n
           | n <- described List.\\ expected
           ]


reifyCons :: Name -> Q [Con]
reifyCons n =
    reify n >>= \case
        TyConI (DataD _ _ _ _ cs _) -> pure cs
        TyConI (NewtypeD _ _ _ _ c _) -> pure [c]
        _ -> fail $ nameBase n <> " is not a data type or newtype"


conName :: Con -> Name
conName = \case
    NormalC n _ -> n
    RecC n _ -> n
    InfixC _ n _ -> n
    ForallC _ _ c -> conName c
    GadtC (n : _) _ _ -> n
    RecGadtC (n : _) _ _ -> n
    _ -> error "conName: unsupported constructor"


-- | The argument fields of a tool constructor, following the same shapes
-- @mcp-server@ accepts: nullary, a record, or a single record-typed argument.
conFieldNames :: Con -> Q [String]
conFieldNames = \case
    NormalC _ [] -> pure []
    RecC _ fields -> pure [nameBase f | (f, _, _) <- fields]
    NormalC _ [(_, ConT param)] ->
        reifyCons param >>= \case
            [RecC _ fields] -> pure [nameBase f | (f, _, _) <- fields]
            _ -> fail $ nameBase param <> " must be a single-constructor record"
    con -> fail $ "Unsupported tool constructor: " <> nameBase (conName con)
