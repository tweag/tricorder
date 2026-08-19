{
  inputs,
  pkgs,
  compiler-nix-name,
  self,
}:
let
  component = {
    # Treat warnings as errors in Nix builds (CI), but not in local dev.
    # Applied to every first-party package.
    ghcOptions = [ "-Werror" ];
    # Make generated documentation suitable for upload to Hackage.
    setupHaddockFlags = [ "--for-hackage" ];
  };
in
pkgs.haskell-nix.cabalProject' {
  src = ../.;
  inherit compiler-nix-name;

  # Add tmp-postgres from flake input
  cabalProjectLocal = import ./tmp-postgres.nix { inherit inputs; };

  # Package-specific configuration
  modules = [
    {
      # Build Haddock (including hyperlinked source) for all packages
      doHaddock = true;

      packages = {
        # Disable tests for tmp-postgres
        tmp-postgres.doCheck = false;

        atelier-prelude = component;
        atelier-core = component;
        atelier-db = component;
        atelier-testing = component;
        atelier-monitoring = component;
        tricorder-mcp = component;

        # Configure tricorder package
        tricorder = component // {
          # Embed the flake's git revision so the released binary carries the
          # correct hash. Falls back to "unknown" on dirty trees (no shortRev).
          preBuild = ''
            export TRICORDER_VERSION="${self.shortRev or "unknown"}"
          '';
        };
      };
    }
  ];
}
