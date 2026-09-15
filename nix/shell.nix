{
  perSystem =
    {
      pkgs,
      self',
      config,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        inputsFrom = [
          config.haskellProjects.${config.ghc.names.default}.outputs.devShell
        ];
        packages =
          builtins.attrValues {
            inherit (pkgs)
              nixfmt
              pre-commit
              tagref
              ;
          }
          ++ [ self'.packages.nix-hpack ];
        shellHook = ''
          ${self'.checks.git-hooks.shellHook}
        '';
      };
    };
}
