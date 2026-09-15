{ packages }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.tricorder;
in
{
  options.programs.tricorder = {
    enable = lib.mkEnableOption "tricorder GHCi build daemon";
    package = lib.mkPackageOption pkgs "tricorder" { } // {
      default = packages.${pkgs.stdenv.hostPlatform.system}.tricorder;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
