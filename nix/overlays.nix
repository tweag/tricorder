{ withSystem, self, ... }: {
  flake.overlays = {
    nix-hpack = final: _: {
      nix-hpack = withSystem final.stdenv.hostPlatform.system (
        { config, ... }: config.packages.nix-hpack
      );
    };
    tricorder = final: _: {
      tricorder = withSystem final.stdenv.hostPlatform.system (
        { config, ... }: config.packages.tricorder
      );
    };
    default =
      let
        overlayNames = builtins.filter (o: o != "default") (builtins.attrNames self.overlays);
        overlays = builtins.foldl' (
          prevOverlay: thisOverlay: final: prev:
          thisOverlay final (prev // prevOverlay final prev)
        ) (_: _: { }) overlayNames;
      in
      overlays;
  };
}
