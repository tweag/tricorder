{
  self,
  withSystem,
  inputs,
  ...
}:
let
  common = import ./package/common.nix;
in
{
  imports = [
    ./apps.nix
    ./shell.nix
    ./checks.nix
    ./ghc-versions.nix
    ./cabal-project.nix
    ./sdists.nix
  ];
  perSystem =
    {
      self',
      lib,
      config,
      system,
      pkgs,
      ...
    }:
    let
      flake = config.legacyPackages.flakes.${config.ghc.names.default};
    in
    {
      _module.args.pkgs =
        let
          nixpkgs = if system == "x86_64-darwin" then inputs.nixpkgs-2605 else inputs.nixpkgs;
        in
        import nixpkgs {
          inherit system;
          overlays = [ inputs.haskell-nix.overlay ];
          config = inputs.haskell-nix.config // {
            allowUnfreePredicate =
              pkg:
              (inputs.haskell-nix.config.allowUnfreePredicate or (_: false)) pkg
              || builtins.elem (inputs.nixpkgs.lib.getName pkg) [
                "ghc-toolchain-lib-ghc-toolchain"
              ];
          };
        };

      cabalProject = lib.genAttrs config.ghc.names.all (compiler-nix-name: {
        inherit compiler-nix-name;
      });

      ghc.versions = {
        default = common.default-ghc-version;
        others = common.additional-ghc-versions;
      };

      packages = flake.packages // {
        nix-hpack = pkgs.callPackage ./package/nix-hpack.nix { };
        default = self'.packages.tricorder;
        tricorder = self'.packages."tricorder:exe:tricorder";
        tricorder-mcp = self'.packages."tricorder-mcp:exe:tricorder-mcp";
      };

      checks = flake.checks;
      apps = flake.apps;

      legacyPackages = {
        project = config.legacyPackages.projects.${config.ghc.names.default};
        flake = config.legacyPackages.flakes.${config.ghc.names.default};
      };
    };

  flake = {
    overlays = {
      tricorder =
        final: _:
        withSystem final.stdenv.hostPlatform.system (
          { self', ... }: {
            tricorder = self'.packages.tricorder;
          }
        );
      nix-hpack =
        final: _:
        withSystem final.stdenv.hostPlatform.system (
          { self', ... }: {
            nix-hpack = self'.packages.nix-hpack;

          }
        );
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
    homeManagerModules.default = import ./nix/home-module.nix { inherit self; };
    nixosModules.default = import ./nix/nixos-module.nix { inherit self; };
  };
}
