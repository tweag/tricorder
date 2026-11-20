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
      extraModules = lib.optional pkgs.stdenv.hostPlatform.isLinux {
        # Dynamic build only (static musl binaries have no rpath to patch).
        # nixpkgs' gmp builds libgmpxx, which drags libstdc++ (gcc-lib)
        # into the closure. The exe only needs libgmp, so repoint the
        # rpath to a gmp built without C++ support.
        packages.tricorder.components.exes.tricorder.postInstall = ''
          exe=$out/bin/tricorder
          newrpath=$(patchelf --print-rpath "$exe" | tr ':' '\n' \
            | sed 's|^/nix/store/[a-z0-9]*-gmp-with-cxx-[^/]*/lib$|${
              pkgs.gmp.override { cxx = false; }
            }/lib|' \
            | paste -sd:)
          patchelf --set-rpath "$newrpath" "$exe"
          # Fail the build if the rewrite stopped matching (for example if
          # nixpkgs renames the gmp package), rather than silently shipping
          # gcc in the closure again.
          if patchelf --print-rpath "$exe" | grep -q 'gmp-with-cxx'; then
            echo "ERROR: $exe still references gmp-with-cxx" >&2
            exit 1
          fi
        '';
      };
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
