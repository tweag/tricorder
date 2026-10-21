{
  self,
  withSystem,
  inputs,
  ...
}:
let
  common = import ./package/common.nix;
in
{
  imports = [
    ./apps.nix
    ./shell.nix
    ./checks.nix
    ./ghc-versions.nix
    ./cabal-project.nix
    ./sdists.nix
  ];
  perSystem =
    {
      self',
      lib,
      config,
      system,
      pkgs,
      ...
    }:
    let
      flake = config.legacyPackages.flakes.${config.ghc.names.default};

      # On Linux, static executables are cross-compiled against musl libc, as
      # glibc does not support being linked statically.  See
      # https://input-output-hk.github.io/haskell.nix/tutorials/cross-compilation.html#static-executables-with-musl-libc
      staticPkgs =
        if pkgs.stdenv.hostPlatform.isLinux then
          {
            x86_64 = pkgs.pkgsCross.musl64;
            aarch64 = pkgs.pkgsCross.aarch64-multiplatform-musl;
          }
          .${pkgs.stdenv.hostPlatform.parsed.cpu.name}
        else
          pkgs;

      staticExeConfig =
        if pkgs.stdenv.hostPlatform.isLinux then
          {
            configureFlags = [
              "--disable-executable-dynamic"
              "--disable-shared"
              "--ghc-option=-optl=-pthread"
              "--ghc-option=-optl=-static"
              "--ghc-option=-optl=-L${staticPkgs.gmp6.override { withStatic = true; }}/lib"
              # haskell.nix's musl overlay keeps libz.a in zlib's main output.
              "--ghc-option=-optl=-L${staticPkgs.zlib}/lib"
            ];
          }
        else
          {
            configureFlags = [ "--disable-executable-dynamic" ];
            libs = [
              pkgs.pkgsStatic.libffi
              pkgs.pkgsStatic.gmp
              pkgs.pkgsStatic.ncurses
            ];
            # libiconv is always present at /usr/lib/libiconv.2.dylib on every
            # Mac, but GHC links against the Nix store copy.  Retarget it to the
            # system path so the binary runs on non-Nix machines.
            # /usr/bin/{otool,install_name_tool} are macOS system tools
            # available in Nix builds.
            postInstall = ''
              for bin in "$out"/bin/*; do
                old=$(/usr/bin/otool -L "$bin" | awk 'NR>1 && /libiconv/ {print $1; exit}')
                [ -n "$old" ] && /usr/bin/install_name_tool -change "$old" /usr/lib/libiconv.2.dylib "$bin"
              done
            '';
          };
      staticProject = import ./package/mk-project.nix {
        inherit self;
        pkgs = staticPkgs;
        compiler-nix-name = config.ghc.names.default;
        doHaddock = false;
        extraModules = [
          {
            packages.tricorder.components.exes.tricorder = staticExeConfig;
            packages.tricorder.components.exes.tricorder-daemon = staticExeConfig;
            packages.tricorder-mcp.components.exes.tricorder-mcp = staticExeConfig;
          }
        ];
      };
      staticFlake = staticProject.flake { };
    in
    {
      _module.args.pkgs =
        let
          nixpkgs = if system == "x86_64-darwin" then inputs.nixpkgs-2605 else inputs.nixpkgs;
        in
        import nixpkgs {
          inherit system;
          overlays = [ inputs.haskell-nix.overlay ];
          config = inputs.haskell-nix.config // {
            allowUnfreePredicate =
              pkg:
              (inputs.haskell-nix.config.allowUnfreePredicate or (_: false)) pkg
              || builtins.elem (inputs.nixpkgs.lib.getName pkg) [
                "ghc-toolchain-lib-ghc-toolchain"
              ];
          };
        };

      cabalProject = lib.genAttrs config.ghc.names.all (compiler-nix-name: {
        inherit compiler-nix-name;
      });

      ghc.versions = {
        default = common.default-ghc-version;
        others = common.additional-ghc-versions;
      };

      packages = flake.packages // {
        nix-hpack = pkgs.callPackage ./package/nix-hpack.nix { };
        default = self'.packages.tricorder;
        tricorder = self'.packages."tricorder:exe:tricorder";
        tricorder-mcp = self'.packages."tricorder-mcp:exe:tricorder-mcp";
        tricorder-static = staticFlake.packages."tricorder:exe:tricorder";
        tricorder-mcp-static = staticFlake.packages."tricorder-mcp:exe:tricorder-mcp";
      };

      checks = flake.checks;
      apps = flake.apps;

      legacyPackages = {
        project = config.legacyPackages.projects.${config.ghc.names.default};
        flake = config.legacyPackages.flakes.${config.ghc.names.default};
      };
    };

  flake = {
    overlays = {
      tricorder =
        _: prev:
        withSystem prev.stdenv.hostPlatform.system (
          { self', ... }: {
            tricorder = self'.packages.tricorder;
          }
        );
      nix-hpack =
        _: prev:
        withSystem prev.stdenv.hostPlatform.system (
          { self', ... }: {
            nix-hpack = self'.packages.nix-hpack;

          }
        );
      default = inputs.nixpkgs.lib.composeManyExtensions (
        builtins.attrValues (removeAttrs self.overlays [ "default" ])
      );
    };
    homeManagerModules.default = import ./home-module.nix { inherit self; };
    nixosModules.default = import ./nixos-module.nix { inherit self; };
  };
}
