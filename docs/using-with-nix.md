# Using with Nix

> [!TIP]
> Configure the binary cache to avoid building GHC from scratch:
>
> ```nix
> nixConfig = {
>   extra-substituters = [
>     "https://cache.iog.io"
>     "https://tweag-tricorder.cachix.org"
>   ];
>   extra-trusted-public-keys = [
>     "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
>     "tweag-tricorder.cachix.org-1:PbwYPJ9gF8Wns14ai0sHK3iblqFd5YUrj0zEzGsJ/wg="
>   ];
> };
> ```

## Try it out

```bash
nix run --accept-flake-config github:atelier-hub/tricorder -- ui
```

`--accept-flake-config` tells Nix to use the binary caches declared in this
flake. Without it, Nix will build the entire Haskell toolchain from source.

## Dev shell

To make `tricorder` available in a project's dev shell without installing it
system-wide:

```nix
inputs.tricorder.url = "github:atelier-hub/tricorder";

devShells.default = pkgs.mkShell {
  packages = [ inputs.tricorder.packages.${system}.tricorder ];
};
```

## Installing

Add the flake input and apply the overlay:

```nix
inputs.tricorder.url = "github:atelier-hub/tricorder";

nixpkgs.overlays = [ inputs.tricorder.overlays.default ];
```

## Home Manager

```nix
imports = [ inputs.tricorder.homeManagerModules.default ];
programs.tricorder.enable = true;
```

## NixOS (without Home Manager)

```nix
imports = [ inputs.tricorder.nixosModules.default ];
programs.tricorder.enable = true;
```
