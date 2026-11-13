{-# LANGUAGE AllowAmbiguousTypes #-}
{-# OPTIONS_GHC -Wno-redundant-constraints #-}
{-# OPTIONS_HADDOCK not-home #-}

-- |
-- Module      : Atelier.FileSystem.Path.Symbol
-- Description : 'Symbol' constructors for 'Absolute' and 'Relative'.
-- Copyright   : (c) <Tweag> 2026
-- License     : MIT
-- Maintainer  : <victor.bakke@tweag.io>
-- Stability   : experimental
-- Portability : POSIX
--
-- Internal types and functions for the @Atelier.FileSystem.*@ family
-- of modules. The API of this module is considered unstable, and will not be
-- reflected in the change log or the package version of this package.
module Atelier.FileSystem.Path.Symbol
    ( absolute
    , abs
    , relative
    , rel
    , StartsWithSlash
    , NoLeadingSlash
    )
where

import GHC.TypeLits
    ( ErrorMessage (..)
    , KnownSymbol
    , Symbol
    , TypeError
    , UnconsSymbol
    , symbolVal
    )
import Prelude hiding (abs, isPrefixOf, join)

import Atelier.FileSystem.Path.Internal
    ( Absolute (..)
    , Relative (..)
    )


-- | Construct an 'Absolute' path from a type-level string. The string must
-- start with @/@.
--
-- >>> toText (absolute @"/usr/bin")
-- "/usr/bin"
--
-- >>> absolute @"usr/bin"
-- TypeError
absolute :: forall s. (KnownSymbol s, StartsWithSlash s) => Absolute
absolute = UnsafeMkAbsolute $ symbolVal (Proxy @s)


-- | Alias for 'absolute'.
abs :: forall s. (KnownSymbol s, StartsWithSlash s) => Absolute
abs = absolute @s


-- | Construct a 'Relative' path from a type-level string. The string must not
-- start with @/@, otherwise this is a type error.
--
-- >>> toText (relative @"foo/bar")
-- "foo/bar"
--
-- >>> relative @"/foo/bar"
-- TypeError
relative :: forall s. (KnownSymbol s, NoLeadingSlash s) => Relative
relative = UnsafeMkRelative $ symbolVal (Proxy @s)


-- | Alias for 'relative'.
rel :: forall s. (KnownSymbol s, NoLeadingSlash s) => Relative
rel = relative @s


type StartsWithSlash s = RequireSlash s (UnconsSymbol s)


type family RequireSlash (s :: Symbol) (m :: Maybe (Char, Symbol)) :: Constraint where
    RequireSlash _ ('Just '( '/', _)) = ()
    RequireSlash s _ =
        TypeError
            ( 'Text "Absolute path must start with '/', but got: "
                :<>: 'ShowType s
            )


type NoLeadingSlash s = RejectSlash s (UnconsSymbol s)


type family RejectSlash (s :: Symbol) (m :: Maybe (Char, Symbol)) :: Constraint where
    RejectSlash s ('Just '( '/', _)) =
        TypeError
            ( 'Text "Relative path must not start with '/', but got: "
                :<>: 'ShowType s
            )
    RejectSlash _ _ = ()
