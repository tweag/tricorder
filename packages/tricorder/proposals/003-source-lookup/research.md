# Research: Package Search

## Open investigations

### GHCi `:list <identifier>` for dependencies

GHCi's `:list <identifier>` command shows source code around an identifier. Per the GHCi
help text it works for loaded modules. It is unclear whether it resolves identifiers from
installed dependencies (e.g. `fromList` from `containers`) or only from the current
project's modules.

**To verify:** start a GHCi session, import `Data.Map.Strict`, and run
`:list Data.Map.Strict.fromList`. If it returns source lines, this could replace or
supplement the haddock HTML approach for identifier-level lookup and is worth integrating.

---

### Binding-level extraction from haddock HTML

Two approaches for extracting a single binding rather than a full module:

**Anchor-based (simpler):** Haddock source HTML has named anchors per top-level
definition — `<a name="v:fromList">`, `<a name="t:Map">` etc. Extraction: find the
anchor, capture lines until the next anchor. No extra dependency, works on the HTML
before full tag-stripping. Likely good enough for a first pass.

**`ghc-lib-parser` (robust):** Parse the stripped source with `ghc-lib-parser` to get a
real AST, then extract the binding plus its type signature, associated instances, and
documentation. Cleaner result but adds a version-coupled dependency (`ghc-lib-parser`
tracks GHC versions the same way `ghc` does). Worth considering as a later upgrade once
the anchor approach is validated.
