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
    flake-utils.url = "github:numtide/flake-utils";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      common = import ./nix/package/common.nix;
      versionToCompilerName = v: "ghc${builtins.replaceStrings [ "." ] [ "" ] v}";
      defaultGhcVersion = versionToCompilerName common.default-ghc-version;
      ghcVersions = map versionToCompilerName common.ghc-versions;
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
        legacyPackages = projects.${defaultGhcVersion} // {
          inherit projects;
        };
      }
    )
    // {
      overlays = {
        tricorder = final: _: {
          tricorder = self.packages.${final.stdenv.hostPlatform.system}.tricorder;
        };
        nix-hpack = final: _: {
          nix-hpack = self.packages.${final.stdenv.hostPlatform.system}.nix-hpack;
        };
        default =
          let
            overlayNames = builtins.filter (o: o != "default") (builtins.attrNames self.overlays);
            overlays = builtins.foldl' (
              prevOverlay: thisOverlay: final: prev:
              thisOverlay final (prev // prevOverlay final prev)
            ) (_: _: { }) overlayNames;
          in
          overlays;
      };
      homeManagerModules.default = import ./nix/home-module.nix;
      nixosModules.default = import ./nix/nixos-module.nix;
    };
}
