{
  # Full flake self, used to embed the git revision in the tricorder binary.
  self,
  # The nixpkgs package set to build against.
  pkgs,
  # GHC compiler name, e.g. "ghc9141".
  compiler-nix-name,
  # Whether to build Haddock (set false for static / release builds).
  doHaddock ? true,
  # Extra haskell.nix modules appended after the base configuration.
  extraModules ? [ ],
}:
let
  component = {
    ghcOptions = [ "-Werror" ];
    setupHaddockFlags = [ "--for-hackage" ];
  };
in
pkgs.haskell-nix.cabalProject' {
  inherit compiler-nix-name;
  src = ../../.;

  modules = [
    {
      inherit doHaddock;
      packages = {
        atelier-prelude = component;
        atelier-core = component;
        tricorder-mcp = component;
        tricorder-types = component;

        tricorder = component // {
          preBuild = ''
            export TRICORDER_VERSION="${self.shortRev or "unknown"}"
          '';
        };
      };
    }
  ]
  ++ extraModules;
}
