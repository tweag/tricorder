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

  component = {
    # Treat warnings as errors in Nix builds (CI), but not in local dev.
    # Applied to every first-party package.
    ghcOptions = [ "-Werror" ];
    # Make generated documentation suitable for upload to Hackage.
    setupHaddockFlags = [ "--for-hackage" ];
  };
  mkProject =
    {
      compiler-nix-name,
      pkgs,
      self,
    }:
    pkgs.haskell-nix.cabalProject' {
      inherit compiler-nix-name;
      src = ../.;
      cabalProjectLocal = ''
        allow-newer: 
          containers,
          base
      '';

      # Package-specific configuration
      modules = [
        {
          # Build Haddock (including hyperlinked source) for all packages
          doHaddock = true;

          packages = {
            atelier-prelude = component;
            atelier-core = component;
            tricorder-mcp = component;
            tricorder-types = component;

            # Configure tricorder package
            tricorder = component // {
              # Embed the flake's git revision so the released binary carries the
              # correct hash. Falls back to "unknown" on dirty trees (no shortRev).
              preBuild = ''
                export TRICORDER_VERSION="${self.shortRev or "unknown"}"
              '';
            };
          };
        }
      ];
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
