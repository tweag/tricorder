{
  perSystem =
    {
      self',
      config,
      pkgs,
      lib,
      ...
    }:
    let
      unusedConstraints = import ./package/unused-constraints.nix;
    in
    {
      apps = {
        tricorder = {
          type = "app";
          program = "${self'.packages.tricorder}/bin/tricorder";
        };

        # Weeder: detects unused code
        weeder = {
          type = "app";
          program = "${pkgs.writeShellScript "weeder-app" ''
            echo "Building project with HIE files..."
            ${pkgs.cabal-install}/bin/cabal build --ghc-options=-fwrite-ide-info
            echo "Running weeder to detect unused code..."
            ${pkgs.haskell-nix.tool config.ghc.names.default "weeder" "latest"}/bin/weeder
          ''}";
        };

        # Reports constraints in nix/package/dependencies.nix that no
        # packages/*/package.nix depends on.
        unused-constraints = {
          type = "app";
          program = "${pkgs.writeShellScript "unused-constraints-app" (
            if unusedConstraints == [ ] then
              ''echo "No unused constraints found."''
            else
              ''
                echo "Unused constraints in nix/package/dependencies.nix:"
                ${lib.concatMapStringsSep "\n" (n: "echo '  - ${n}'") unusedConstraints}
                exit 1
              ''
          )}";
        };

        get-changelog-section = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "get-changelog-section";
              runtimeInputs = [ pkgs.gawk ];
              text = ''
                version="''${1:?Usage: $0 <version> [changelog-file]}"
                changelog="''${2:-tricorder/CHANGELOG.md}"
                version="''${version#v}"

                if [[ ! -f "$changelog" ]]; then
                  echo "error: missing changelog file: $changelog" >&2
                  exit 1
                fi

                section=$(awk -v ver="$version" '
                  /^## \[/ {
                    if (in_section) exit
                    if ($0 ~ "^## \\[" ver "\\]") { in_section = 1; print; next }
                  }
                  in_section { print }
                ' "$changelog")

                if [[ -z "$section" ]]; then
                  echo "error: version $version not found in $changelog" >&2
                  exit 1
                fi
                printf '%s\n' "$section"
              '';
            }
          );
        };
      };
    };
}
