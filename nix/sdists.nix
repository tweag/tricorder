{
  perSystem =
    { pkgs, ... }:
    let
      common = import ./package/common.nix;
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
      individualSdists = builtins.listToAttrs (
        map (name: {
          name = "${name}-sdist";
          value = mkSdist name;
        }) common.packageNames
      );
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
