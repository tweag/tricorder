# Verification builds for the `canvas` flake template (templates/canvas).
#
# The template ships as a standalone flake whose app depends on *released*
# atelier packages from Hackage, so the template's own `nix flake check` never
# exercises the in-development atelier sources living in this repo. These two
# checks close that gap:
#
#   * canvas-hackage — build the template exactly as it ships (atelier-* from
#     Hackage). Proves the template is buildable/publishable as released.
#   * canvas-local   — build the canvas app against this repo's in-development
#     atelier sources, catching API or version-bound drift before a release
#     breaks the template.
#
# Both are wired into legacyChecks (see nix/outputs.nix) for the template's
# target GHC only, so the existing CI matrix builds them automatically.
{
  inputs,
  pkgs,
  compiler-nix-name,
}:
let
  # atelier-db's test suite depends on tmp-postgres (not on Hackage); the solver
  # needs it even though we only build canvas's own components.
  tmpPostgres = import ./tmp-postgres.nix { inherit inputs; };

  modules = [ { packages.tmp-postgres.doCheck = false; } ];

  # The template as published: atelier-* come from Hackage via this repo's
  # `hackage` flake input. If this fails because a freshly released atelier
  # version isn't in the index yet, bump the `hackage` input.
  hackageProject = pkgs.haskell-nix.cabalProject' {
    src = ../templates/canvas;
    inherit compiler-nix-name modules;
    cabalProjectLocal = tmpPostgres;
  };

  # The same canvas app, but resolving atelier-* from this repo's source. The
  # inline cabalProject replaces the repo-root one (which builds tricorder) with
  # just canvas plus the atelier packages it depends on.
  localProject = pkgs.haskell-nix.cabalProject' {
    src = ../.;
    inherit compiler-nix-name modules;
    cabalProject = ''
      packages:
        atelier-prelude
        atelier-core
        atelier-db
        atelier-monitoring
        templates/canvas/canvas

      tests: True

      -- Mirror the template's allow-newer overrides (see its cabal.project).
      allow-newer: tasty-hspec:QuickCheck

      package canvas
        optimization: False

      constraints:
        -- rel8 needs semialign < 1.4 (circuithub/rel8#402)
        semialign < 1.4
    '';
    cabalProjectLocal = tmpPostgres;
  };

  # Build the canvas exe and compile its test suite — enough to catch breakage
  # in the atelier API the template builds against. We compile rather than run
  # the tests to keep the check hermetic.
  bundle =
    name: project:
    pkgs.symlinkJoin {
      name = "canvas-${name}-${compiler-nix-name}";
      paths = [
        project.hsPkgs.canvas.components.exes.canvas
        project.hsPkgs.canvas.components.tests.canvas-test
      ];
    };
in
{
  canvas-hackage = bundle "hackage" hackageProject;
  canvas-local = bundle "local" localProject;
}
