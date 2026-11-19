{ self, ... }: {
  perSystem =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
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
              "--ghc-option=-Wno-missed-extra-shared-lib"
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
              # Without this, the zlib Haskell package links the dynamic
              # libz.dylib from the Nix store, breaking portability.
              pkgs.pkgsStatic.zlib
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
          # On darwin the zlib Haskell package resolves libz through its own
          # pkgconfig dependency, which is the dynamic nixpkgs zlib; adding a
          # static zlib to the exes' `libs` is not enough.  Point the library
          # itself at the static build.
          (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
            packages.zlib.components.library.pkgconfig = lib.mkForce [ [ pkgs.pkgsStatic.zlib ] ];
          })
        ];
      };
      staticFlake = staticProject.flake { };
      # The statically linked TUI embeds ncurses' compiled-in terminfo
      # directory, which makes Nix keep ncurses (and musl, via ncurses' own
      # tools) in the closure for a fallback path.  ncurses also searches
      # $TERMINFO, ~/.terminfo, $TERMINFO_DIRS and the system terminfo
      # directories, so scrub the reference.  Linux only; the darwin build
      # has no such reference.
      scrubTerminfo =
        exe:
        if pkgs.stdenv.hostPlatform.isLinux then
          pkgs.runCommand exe.name { nativeBuildInputs = [ pkgs.buildPackages.removeReferencesTo ]; } ''
            mkdir -p $out/bin
            cp ${exe}/bin/tricorder $out/bin/
            chmod +w $out/bin/tricorder
            remove-references-to -t ${staticPkgs.ncurses} $out/bin/tricorder
          ''
        else
          exe;
    in
    {
      packages = {
        tricorder-static = scrubTerminfo staticFlake.packages."tricorder:exe:tricorder";
        tricorder-mcp-static = staticFlake.packages."tricorder-mcp:exe:tricorder-mcp";
      };
    };
}
