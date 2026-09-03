{
  description = "Canvas";

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
    nixpkgs.follows = "haskell-nix/nixpkgs";
    nixpkgs-nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    flake-utils.url = "github:numtide/flake-utils";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tmp-postgres = {
      url = "github:jfischoff/tmp-postgres";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      # GHC versions to build. The first is the default; add more to build a
      # matrix in CI. Kept to one to start so dev builds stay fast.
      ghcVersionList = [ "9.10.3" ];
      versionToCompilerName = v: "ghc${builtins.replaceStrings [ "." ] [ "" ] v}";
      defaultGhcVersion = versionToCompilerName (builtins.head ghcVersionList);
      ghcVersions = map versionToCompilerName ghcVersionList;
      lib = inputs.nixpkgs.lib;
    in
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (
      system:
      let
        projects = lib.genAttrs ghcVersions (
          compiler-nix-name:
          import ./nix/outputs.nix {
            inherit
              inputs
              system
              self
              compiler-nix-name
              ;
          }
        );
      in
      projects.${defaultGhcVersion}
      // {
        legacyChecks = lib.mergeAttrsList (
          map ({ legacyChecks, ... }: legacyChecks) (builtins.attrValues projects)
        );
      }
    )
    // {
      overlays = import ./nix/overlays.nix self.packages;
    };
}
