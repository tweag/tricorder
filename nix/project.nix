{ inputs, ... }:
let
  common = import ./package/common.nix;
in
{
  perSystem =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      haskellProjects = lib.genAttrs config.ghc.names.all (ghcName: {
        basePackages = pkgs.haskell.packages.${ghcName};

        defaults.settings.local = {
          check = true;
          haddock = true;
        };

        projectRoot = lib.fileset.toSource {
          root = ../.;
          fileset = lib.fileset.unions [
            ../cabal.project
            ../LICENSE
            ../packages
          ];
        };

        packages = {
          mcp-server.source = inputs.mcp-server;
          http-types.source = inputs.http-types;
        };

        devShell = {
          enable = ghcName == config.ghc.names.default;
          tools = hp: {
            inherit (hp)
              cabal-install
              fourmolu
              ghc
              hlint
              tasty-discover
              weeder
              ;
          };
        };
      });

      legacyPackages.haskellProjects = config.haskellProjects;

      ghc.versions = {
        default = common.default-ghc-version;
        others = common.additional-ghc-versions;
      };
    };
}
