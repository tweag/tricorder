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

      # Terminfo entries compiled into libtinfo, so the TUI still starts on
      # hosts without a terminfo database (minimal containers, and so on).
      # The released binary is copied out of the Nix store, so it cannot rely
      # on ncurses' own database being present.
      ncursesWithFallbacks = staticPkgs.ncurses.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--with-fallbacks=${
            lib.concatStringsSep "," [
              "xterm"
              "xterm-256color"
              "xterm-color"
              "screen"
              "screen-256color"
              "tmux"
              "tmux-256color"
              "linux"
              "vt100"
              "alacritty"
              "foot"
              "wezterm"
            ]
          }"
        ];
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.buildPackages.ncurses ];
      });

      staticExeConfig =
        if pkgs.stdenv.hostPlatform.isLinux then
          {
            configureFlags = [
              "--disable-executable-dynamic"
              "--disable-shared"
              "--ghc-option=-optl=-pthread"
              "--ghc-option=-optl=-static"
              "--ghc-option=-Wno-missed-extra-shared-lib"
              # Listed first so the fallback-enabled ncurses wins over the stock one.
              "--ghc-option=-optl=-L${lib.getLib ncursesWithFallbacks}/lib"
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
      # The statically linked executables embed store paths that nothing needs
      # at runtime, which makes Nix keep them in the closure:
      #  - ncurses' compiled-in terminfo directory (ncurses also searches
      #    $TERMINFO, ~/.terminfo, $TERMINFO_DIRS and the system terminfo
      #    directories, and the common entries are compiled in as fallbacks),
      #  - the -L directories of the static libraries linked in above, plus
      #    everything those drag along (musl, libstdc++ via gmp's libgmpxx).
      # Scrub them.  Linux only; the darwin build has no such references.
      scrubbedRefs = [
        ncursesWithFallbacks
        staticPkgs.ncurses
        staticPkgs.zlib
        (staticPkgs.gmp6.override { withStatic = true; })
      ];
      scrubReferences =
        exeName: exe:
        if pkgs.stdenv.hostPlatform.isLinux then
          pkgs.runCommand exe.name { nativeBuildInputs = [ pkgs.buildPackages.removeReferencesTo ]; } ''
            mkdir -p $out/bin
            cp ${exe}/bin/${exeName} $out/bin/
            chmod +w $out/bin/${exeName}
            remove-references-to ${
              lib.concatMapStringsSep " " (ref: "-t ${ref}") scrubbedRefs
            } $out/bin/${exeName}
          ''
        else
          exe;
    in
    {
      packages = {
        tricorder-static = scrubReferences "tricorder" staticFlake.packages."tricorder:exe:tricorder";
        tricorder-daemon-static =
          scrubReferences "tricorder-daemon"
            staticFlake.packages."tricorder:exe:tricorder-daemon";
        tricorder-mcp-static =
          scrubReferences "tricorder-mcp"
            staticFlake.packages."tricorder-mcp:exe:tricorder-mcp";
      };
    };
}
