{ flake-parts-lib, lib, ... }:
let
  versionToCompilerName = v: "ghc${builtins.replaceStrings [ "." ] [ "" ] v}";
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, ... }:
    {
      options.ghc = {
        versions = {
          default = lib.mkOption {
            description = "Default GHC version to use.";
            example = "ghc9103";
            type = lib.types.str;
          };
          others = lib.mkOption {
            description = "Other GHC versions to build and test against.";
            example = [
              "ghc9103"
              "ghc9141"
            ];
            type = with lib.types; listOf str;
          };
          all = lib.mkOption {
            description = "All GHC versions in one list.";
            internal = true;
            readOnly = true;
            type = with lib.types; listOf str;
            default = [ config.ghc.versions.default ] ++ config.ghc.versions.others;
          };
        };

        names = {
          default = lib.mkOption {
            description = "Compiler name of the default GHC version.";
            internal = true;
            readOnly = true;
            type = lib.types.str;
            default = versionToCompilerName config.ghc.versions.default;
          };
          others = lib.mkOption {
            description = "Compiler name of other GHC versions to build and test against.";
            internal = true;
            readOnly = true;
            type = with lib.types; listOf str;
            default = map versionToCompilerName config.ghc.versions.others;
          };
          all = lib.mkOption {
            description = "Compiler names of all GHC versions in one list.";
            internal = true;
            readOnly = true;
            type = with lib.types; listOf str;
            default = [ config.ghc.names.default ] ++ config.ghc.names.others;
          };
        };
      };
    }
  );
}
