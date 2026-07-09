-- | SPIKE: this effect is deleted by proposal 008. In the real change the file
-- is removed and the .cabal regenerated via @nix-hpack@; here it is emptied to
-- avoid a module-discovery regen + daemon restart mid-spike. Nothing imports it
-- any more.
module Tricorder.Effects.PostBuildStore () where

