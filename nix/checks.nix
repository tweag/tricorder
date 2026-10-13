{ self, inputs, ... }: {
  imports = [ inputs.git-hooks.flakeModule ];
  perSystem =
    {
      lib,
      self',
      pkgs,
      config,
      ...
    }:
    let
      common = import ./package/common.nix;
      unusedConstraints = import ./package/unused-constraints.nix;
      staticCheck =
        {
          binaryName,
          binary,
          # Shell snippet to smoke-test the binary after the portability check.
          # Defaults to --version (suitable for CLI tools).  Pass null to skip
          # execution entirely, or override for servers that have no --version.
          runCheck ? ''"${binary}" --version'',
        }:
        let
          portabilityCheck =
            if pkgs.stdenv.hostPlatform.isLinux then
              ''
                if ! file "${binary}" | grep -q "statically linked"; then
                  echo "ERROR: ${binaryName} is not statically linked:" >&2
                  file "${binary}" >&2
                  exit 1
                fi
              ''
            else
              ''
                nix_deps=$(otool -L "${binary}" | tail -n +2 | grep '/nix/store' || true)
                if [ -n "$nix_deps" ]; then
                  echo "ERROR: ${binaryName} has /nix/store runtime dependencies:" >&2
                  echo "$nix_deps" >&2
                  exit 1
                fi
              '';
        in
        pkgs.runCommand "${binaryName}-portable"
          {
            nativeBuildInputs = [
              pkgs.file
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.darwin.cctools ];
          }
          ''
            ${portabilityCheck}
            ${lib.optionalString (runCheck != null) runCheck}
            mkdir -p "$out"
            echo "ok" > "$out/check"
          '';
    in
    {
      pre-commit.settings.hooks = {
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
          entry = "${self'.packages.nix-hpack}/bin/nix-hpack";
          pass_filenames = false;
        };
        # Validate tagref cross-references (no dangling refs / duplicate tags).
        tagref = {
          enable = true;
          entry = "${pkgs.tagref}/bin/tagref check";
          pass_filenames = false;
        };
      };
      checks = {
        tricorder = self'.packages.tricorder;

        tricorder-static-portable = staticCheck {
          binaryName = "tricorder-static";
          binary = "${self'.packages.tricorder-static}/bin/tricorder";
        };
        tricorder-mcp-static-portable = staticCheck {
          binaryName = "tricorder-mcp-static";
          binary = "${self'.packages.tricorder-mcp-static}/bin/tricorder-mcp";
          # tricorder-mcp is an MCP server with no --version flag; feed it a
          # closed stdin (its normal shutdown trigger) and suppress the
          # "stdin closed - shutting down" log so CI output stays clean.
          runCheck = ''"${self'.packages.tricorder-mcp-static}/bin/tricorder-mcp" </dev/null 2>/dev/null'';
        };

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

      legacyPackages = lib.genAttrs config.ghc.names.all (compiler-nix-name: {
        all-checks = pkgs.symlinkJoin {
          name = "all-checks-${compiler-nix-name}";
          paths =
            builtins.attrValues
              self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.flakes.${compiler-nix-name}.packages
            ++
              builtins.attrValues
                self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.flakes.${compiler-nix-name}.checks;
        };
      });
    };
}
