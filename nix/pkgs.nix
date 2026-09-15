{
  inputs,
  system,
  project,
  shell,
}:
import (if system == "x86_64-darwin" then inputs.nixpkgs-2605 else inputs.nixpkgs) {
  inherit system;
  overlays = [
    inputs.haskell-nix.overlay
    (final: _: {
      tricorderProject = final.haskell-nix.hix.project (
        project
        // {
          # uncomment with your current system for `nix flake show` to work:
          # evalSystem = "x86_64-linux";
          inherit shell;
        }
      );
      tricorder = (final.tricorderProject.flake { }).packages."tricorder:exe:tricorder";
      nix-hpack = final.callPackage ./package/nix-hpack.nix { };
    })
  ];
  config = inputs.haskell-nix.config // {
    allowUnfreePredicate =
      pkg:
      (inputs.haskell-nix.config.allowUnfreePredicate or (_: false)) pkg
      || builtins.elem (inputs.nixpkgs.lib.getName pkg) [
        "ghc-toolchain-lib-ghc-toolchain"
      ];
  };
}
