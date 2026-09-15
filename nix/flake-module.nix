{ self, ... }:
{
  imports = [
    ./apps.nix
    ./checks.nix
    ./overlays.nix
    ./shell.nix
    ./project.nix
    ./sdists.nix
    ./ghc-versions.nix
  ];

  perSystem =
    {
      self',
      pkgs,
      config,
      ...
    }:
    let
      project = config.haskellProjects.${config.ghc.names.default};
    in
    {
      packages = {
        nix-hpack = pkgs.callPackage ./package/nix-hpack.nix { };
        tricorder = project.outputs.packages.tricorder.package;
        tricorder-mcp = project.outputs.packages.tricorder-mcp.package;
        default = self'.packages.tricorder;
      };
    };

  flake = {
    homeManagerModules.default = import ./home-module.nix { packages = self.packages; };
    nixosModules.default = import ./nixos-module.nix { packages = self.packages; };
  };
}
