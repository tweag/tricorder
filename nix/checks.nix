{
  compiler-nix-name,
  pkgs,
  system,
  inputs,
  self,
}:
let
  inherit (pkgs) lib;
  common = import ./package/common.nix;
  unusedConstraints = import ./package/unused-constraints.nix;
in
{
  checks = {
    git-hooks = inputs.git-hooks.lib.${system}.run {
      src = ../.;
      hooks = {
        fourmolu = {
          enable = true;
          package = pkgs.fourmolu;
        };
        hlint = {
          enable = true;
          package = pkgs.hlint;
        };
        nixfmt = {
          enable = true;
          package = pkgs.nixfmt;
        };
        nix-hpack = {
          enable = true;
          # Run whenever anything that feeds .cabal generation changes:
          #   - *.hs / *.lhs / *.hs-boot : hpack auto-discovers modules from the
          #     source tree, so adding/removing one changes the generated .cabal
          #   - *.cabal                  : catches hand-edits — nix-hpack rewrites
          #     the file from package.nix, so the commit fails if a checked-in
          #     .cabal drifted from its source
          #   - package.nix              : the per-package hpack source
          #   - nix/package/*.nix        : shared constraints / common options
          # pre-commit only runs a hook when a *staged* file matches `files`, so
          # the old package.nix-only pattern let direct .cabal edits (and module
          # additions) through locally; CI runs every hook unconditionally and
          # caught them. This widens the local trigger to match CI.
          files = "(\\.l?hs(-boot)?$)|(\\.cabal$)|((^|/)package\\.nix$)|((^|/)nix/package/.*\\.nix$)";
          entry = "${pkgs.nix-hpack}/bin/nix-hpack";
          pass_filenames = false;
        };
        # Validate tagref cross-references (no dangling refs / duplicate tags).
        tagref = {
          enable = true;
          entry = "${pkgs.tagref}/bin/tagref check";
          pass_filenames = false;
        };
      };
    };
    tricorder = pkgs.tricorder;
    cabal-check =
      pkgs.runCommand "cabal-check"
        {
          packagenames = builtins.concatStringsSep "\n" common.packageNames;
          buildInputs = [
            pkgs.cabal-install
            pkgs.writableTmpDirAsHomeHook
          ];
        }
        ''
          for package in $packagenames; do
            echo "Checking $package" >&2
            (cd "${../.}/packages/$package" && cabal check)
          done
          # Ensuring $out is a directory makes this check compatible with
          # symlinkJoin.
          mkdir -p "$out"
          touch "$out/cabal-check-ok"
        '';
    unused-constraints =
      pkgs.runCommand "unused-constraints"
        {
          unused_constraints = lib.concatMapStringsSep "\n" (s: "- ${s}") unusedConstraints;
        }
        ''
          if test -z "$unused_constraints"; then
            mkdir -p "$out"
            echo "ok" > "$out/check"
          else
            echo "There are unused version constraints in ./nix/package/dependencies.nix:" >&2
            echo "$unused_constraints" >&2
            exit 1
          fi
        '';
  };

  legacyPackages = {
    all-checks = pkgs.symlinkJoin {
      name = "all-checks-${compiler-nix-name}";
      paths =
        builtins.attrValues
          self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.projects.${compiler-nix-name}.packages
        ++
          builtins.attrValues
            self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.projects.${compiler-nix-name}.checks;
    };
  };
}
