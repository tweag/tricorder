{
  writeText,
  writeShellScriptBin,
  nix,
  hpack,
  nushell,
}:
let
  script = writeText "nix-hpack.nu" /* nu */ ''
    if (which nix-instantiate | length) <= 0 {
      $env.PATH = $env.PATH | prepend '${nix}/bin'
    }

    $env.PATH = $env.PATH | prepend '${hpack}/bin'

    ${builtins.readFile ./nix-hpack.nu}
  '';
in
writeShellScriptBin "nix-hpack" ''
  ${nushell}/bin/nu --no-history --no-config-file ${script} "$@"
''
