# Convert `package.nix` files to `.cabal` files, in the spirit of `hpack`.
#
# By default, the generated package.yaml file is deleted once hpack has
# generated the .cabal file. Defaults to converting every package under the
# current working directory.
def main [
    --keep (-k) # Keep the generated package.yaml file.
    ...packages: string # Path to a package directory containing a 'package.nix' to convert.
]: nothing -> nothing {
    $packages
    | default --empty {
        # If no packages are specified, find all packages in the current
        # directory.
        glob --no-dir '**/package.nix' | each { path dirname }
    }
    | each {|package_path|
        print -e $"Converting ($package_path)"
        let source = $"($package_path)/package.nix"
        if not ($source | path exists) {
            print -e $"No package.nix file found in ($package_path)"
            exit 1
        }

        let temp_yaml = $"($package_path)/package.yaml"
        # nix-instantiate tries to initialize /nix/var/nix on startup, which
        # fails in a sandbox.
        let nix_state = mktemp --directory
        $env.NIX_STATE_DIR = $nix_state
        $env.NIX_LOG_DIR = $"($nix_state)/log"
        ^nix-instantiate --strict --json --eval $source | from json | to yaml | save -f $temp_yaml
        rm -rf $nix_state
        ^hpack --silent $temp_yaml
        if not $keep {
          rm -rf $temp_yaml
        }
    }
    | ignore
}
