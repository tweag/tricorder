{
  perSystem =
    {
      config,
      pkgs,
      lib,
      system,
      ...
    }:
    let
      project = config.legacyPackages.project;
      compiler = config.ghc.names.default;
      directory = "nix/materialized/${system}/${compiler}";
      toolSpecs = {
        fourmolu = { };
        ghcid = { };
        haskell-language-server.cabalProjectLocal = ''
          allow-newer:
            base,
            containers
        '';
        hlint.cabalProjectLocal = ''
          allow-newer: base
        '';
        hoogle = { };
        tasty-discover = { };
        weeder = { };
      };
      tools = lib.mapAttrs (
        name: spec:
        let
          path = ./materialized + "/${system}/${compiler}/${name}";
        in
        spec
        // {
          inherit (import ./package/common.nix) index-state;
          materialized = if builtins.pathExists path then path else null;
        }
      ) toolSpecs;
      projects = {
        inherit project;
      }
      // lib.mapAttrs (name: spec: (project.tool name spec).project) tools;
    in
    {
      legacyPackages.materialization = { inherit tools projects; };
      checks.materialization = pkgs.linkFarm "check-materialization" (
        lib.mapAttrsToList (name: p: {
          inherit name;
          path = (p.appendModule { checkMaterialization = true; }).plan-nix;
        }) projects
      );
      apps.update-materialization = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "update-materialization" ''
            set -eu
            test -f flake.nix && test -f nix/materialization.nix || {
              echo "Run this command from the repository root." >&2
              exit 1
            }
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (name: p: ''
                ${p.plan-nix.passthru.generateMaterialized} "${directory}/${name}"
              '') projects
            )}
          ''
        );
      };
    };
}
