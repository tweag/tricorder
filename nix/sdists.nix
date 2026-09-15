{
  perSystem =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
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
            cp -r ${../packages/${package}} ./package
            chmod 777 ./package
            cd ./package
            cabal sdist -o "$out"
          '';
      individualSdists = lib.pipe config.haskellProjects.${config.ghc.names.default}.outputs.packages [
        builtins.attrNames
        (map (name: {
          name = "${name}-sdist";
          value = mkSdist name;
        }))
        builtins.listToAttrs
      ];
      packages = individualSdists // {
        sdists = pkgs.symlinkJoin {
          name = "sdists";
          paths = builtins.attrValues individualSdists;
        };
      };
    in
    {
      inherit packages;
    };
}
