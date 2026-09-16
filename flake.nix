{
  description = "Tricorder";

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://tweag-tricorder.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "tweag-tricorder.cachix.org-1:PbwYPJ9gF8Wns14ai0sHK3iblqFd5YUrj0zEzGsJ/wg="
    ];
    allow-import-from-derivation = true;
  };

  inputs = {
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskell-nix/nixpkgs-unstable";
    # nixpkgs unstable (26.11) dropped x86_64-darwin, and `eachSystem` below
    # evaluates *every* supported system to collect its output names — so one
    # unimportable system breaks `nix develop` on all of them.  Keep the last
    # pin that supports it and use it for that system only.
    nixpkgs-2605.follows = "haskell-nix/nixpkgs-2605";
    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        ./nix/flake-module.nix
      ];
    };
}
