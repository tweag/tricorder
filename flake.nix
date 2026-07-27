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
    nixpkgs.follows = "haskell-nix/nixpkgs";
    nixpkgs-nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    haskell-nix = {
      url = "github:input-output-hk/haskell.nix";
      inputs = {
        hackage.follows = "hackage";
      };
    };

    hackage = {
      url = "github:input-output-hk/hackage.nix";
      flake = false;
    };

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
        legacyChecks = lib.mergeAttrsList (
          map ({ legacyChecks, ... }: legacyChecks) (builtins.attrValues projects)
        );
      }
    )
    // {
      overlays = import ./nix/overlays.nix self.packages;
      homeManagerModules.default = import ./nix/home-module.nix;
      nixosModules.default = import ./nix/nixos-module.nix;

      # Atelier-based web-server starter. Instantiate with:
      #   nix flake init -t github:tweag/tricorder#canvas
      templates.canvas = {
        path = ./templates/canvas;
        description = "Atelier-based web server starter (library + executable, WAI/Warp, rel8/Postgres, haskell.nix)";
        welcomeText = ''
          # canvas — atelier-based web server starter

          You now have a haskell.nix project with a library, a WAI/Warp executable,
          rel8/hasql Postgres access, sqitch migrations, and a dev shell.

          Next steps:
          - `nix develop` (or `direnv allow`) to enter the dev shell
          - `nix run .#postgres` then `sqitch deploy dev` for a local database
          - `tricorder ui` to start the development server (builds and runs tests)
          - `cabal run canvas` to start the server

          `canvas` is a placeholder name — see README.md for how to rename it.
          Edit `canvas/package.yaml` (not the generated `.cabal`) to change dependencies.
        '';
      };
      templates.default = self.templates.canvas;
    };
}
