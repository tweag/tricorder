{
  self,
  flake-parts-lib,
  lib,
  ...
}:
let
  inherit (lib.types)
    submodule
    lazyAttrsOf
    anything
    str
    ;

  mkProject =
    {
      compiler-nix-name,
      pkgs,
      self,
    }:
    import ./package/mk-project.nix {
      inherit self pkgs compiler-nix-name;
    };
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      self',
      pkgs,
      config,
      ...
    }:
    {
      options.cabalProject = lib.mkOption {
        description = "Cabal projects to build";
        type = lazyAttrsOf (
          submodule (
            { config, ... }: {
              options = {
                compiler-nix-name = lib.mkOption {
                  description = "Name of compiler to use";
                  type = str;
                };
                project = lib.mkOption {
                  description = "Created project";
                  type = anything;
                  readOnly = true;
                };
              };
              config = {
                project = mkProject {
                  inherit self pkgs;
                  inherit (config) compiler-nix-name;
                };
              };
            }
          )
        );
      };
      config = {
        legacyPackages.projects = lib.mapAttrs (_: x: x.project) config.cabalProject;
        legacyPackages.flakes = lib.mapAttrs (_: x: x.flake { }) self'.legacyPackages.projects;
      };
    }
  );
}
