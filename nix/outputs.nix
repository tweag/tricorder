{
  inputs,
  system,
  self,
  # GHC version to use across all tools and the project
  compiler-nix-name,
}:
let
  # Initialize package set with haskell.nix
  pkgs = import ./pkgs.nix { inherit inputs system; };
  common = import ./package/common.nix;

  # Configure haskell.nix project
  project = import ./project.nix {
    inherit
      inputs
      pkgs
      compiler-nix-name
      self
      ;
  };

  # Get the project flake for packages
  projectFlake = project.flake { };

  # Tools and binaries used by git-hooks and in the dev shell
  tools = {
    inherit nix-hpack;
    inherit (pkgs)
      fourmolu
      hlint
      nixfmt
      ;
  };

  inherit (pkgs) lib;

  # The cabal executable is named `tricorder`, so it can be consumed directly.
  tricorder = projectFlake.packages."tricorder:exe:tricorder";

  # Git hooks check (defined once, used in both checks and shell)
  gitHooks = inputs.git-hooks.lib.${system}.run {
    src = ../.;
    hooks = {
      fourmolu = {
        enable = true;
        package = tools.fourmolu;
        # Uses a different fourmolu config
        excludes = [ "templates/canvas" ];
      };
      hlint = {
        enable = true;
        package = tools.hlint;
      };
      nixfmt = {
        enable = true;
        package = tools.nixfmt;
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
        entry = "${nix-hpack}/bin/nix-hpack";
        pass_filenames = false;
        # The template has no package.nix and isn't part of this cabal
        # project; keep nix-hpack from triggering on its files.
        excludes = [ "^templates/" ];
      };
      # Validate tagref cross-references (no dangling refs / duplicate tags).
      tagref = {
        enable = true;
        entry = "${pkgs.tagref}/bin/tagref check";
        pass_filenames = false;
      };
    };
  };
  nix-hpack = pkgs.callPackage ./package/nix-hpack.nix { };

  # Canvas flake-template verification builds, gated to the template's target
  # GHC (see nix/template.nix and nix/template-checks.nix).
  templateChecks = import ./template.nix { inherit inputs pkgs compiler-nix-name; };

  checks = projectFlake.checks // {
    git-hooks = gitHooks;
    # Ensure the executable builds in CI
    tricorder = tricorder;
    # Ensure the overlay correctly exposes pkgs.tricorder
    overlay =
      pkgs.runCommand "check-overlay"
        {
          tricorder =
            (pkgs.extend (
              (import ./overlays.nix {
                ${pkgs.stdenv.system}.default = tricorder;
              }).default
            )).tricorder;
        }
        ''
          ls -la
          test -x $tricorder/bin/tricorder
          # Ensuring $out is a directory makes this check compatible with
          # symlinkJoin.
          mkdir -p $out
          touch $out/check-overlay-ok
        '';
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
  };

  mkSdist =
    package:
    pkgs.runCommand "${package}-sdist"
      {
        nativeBuildInputs = [
          pkgs.cabal-install
          pkgs.writableTmpDirAsHomeHook
        ];
      }
      ''
        cp -r ${../${package}} ./package
        chmod 777 ./package
        cd ./package
        cabal sdist -o "$out"
      '';
  sdists = builtins.listToAttrs (
    map (name: {
      name = "${name}-sdist";
      value = mkSdist name;
    }) common.packageNames
  );
  mkDocs =
    package:
    let
      pkg =
        projectFlake.packages."${package}:lib:${package}"
          or projectFlake.packages."${package}:lib:${package}-internal";
    in
    pkg.passthru.haddock.doc;
  docs = builtins.listToAttrs (
    map (name: {
      name = "${name}-docs";
      value = mkDocs name;
    }) common.packageNames
  );
in
{
  # Expose packages built by haskell.nix
  packages =
    projectFlake.packages
    // sdists
    // docs
    // {
      default = tricorder;
      tricorder = tricorder;
      tricorder-mcp = projectFlake.packages."tricorder-mcp:exe:tricorder-mcp";
      inherit nix-hpack;
      sdists = pkgs.symlinkJoin {
        name = "sdists";
        paths = builtins.attrValues sdists;
      };
    };

  # Development shell
  devShells.default = import ./shell.nix {
    pkgs = pkgs.extend (_: _: { inherit nix-hpack; });
    inherit
      project
      gitHooks
      tools
      ;
  };

  # Custom apps
  apps = {
    tricorder = {
      type = "app";
      program = "${tricorder}/bin/tricorder";
    };

    # Weeder: detects unused code
    weeder = {
      type = "app";
      program = "${pkgs.writeShellScript "weeder-app" ''
        echo "Building project with HIE files..."
        ${pkgs.cabal-install}/bin/cabal build --ghc-options=-fwrite-ide-info
        echo "Running weeder to detect unused code..."
        ${pkgs.haskell-nix.tool compiler-nix-name "weeder" "latest"}/bin/weeder
      ''}";
    };

    # HLint auto-fix
    hlint-fix = {
      type = "app";
      program = "${pkgs.writeShellScript "hlint-fix-app" ''
        echo "Running hlint --refactor on all Haskell files..."
        export PATH="${pkgs.haskell-nix.tool compiler-nix-name "apply-refact" "latest"}/bin:$PATH"
        find ${builtins.concatStringsSep " " common.packageNames} -name "*.hs" -exec ${
          pkgs.haskell-nix.tool compiler-nix-name "hlint" "latest"
        }/bin/hlint --refactor --refactor-options="-i" {} \;
        echo "Hlint refactoring complete!"
      ''}";
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

  legacyChecks.${compiler-nix-name} = {
    all = pkgs.symlinkJoin {
      name = "all-checks-${compiler-nix-name}";
      paths = builtins.attrValues checks;
    };
    inherit templateChecks;
  };

  legacyPackages.projectFlake.${compiler-nix-name} = projectFlake;

  inherit checks;
}
