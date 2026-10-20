module Tricorder.SourceLookup.ReexportLimits
    ( ReexportLimits (..)
    , defaultReexportLimits
    )
where


-- | Bounds on the re-export search for a symbol the queried module does not
-- define itself (see 'followReexports').
data ReexportLimits = ReexportLimits
    { maxDepth :: Word
    -- ^ Most re-export hops to follow; @0@ disables following re-exports.
    , maxModules :: Word
    -- ^ Most modules to read during the search.
    }
    deriving stock (Eq, Show)


-- | Enough for the deepest chains seen in practice (@Prelude#Maybe@ takes 3
-- hops through @ghc-internal@) while keeping a miss cheap.
defaultReexportLimits :: ReexportLimits
defaultReexportLimits = ReexportLimits {maxDepth = 5, maxModules = 24}
