{
  description = "odee development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    pkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
  };

  outputs = { self, pkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: {
      defaultPackage = (import ./default.nix {
        pkgs = pkgs.legacyPackages.${system};
      }).odee;
      devShell = (import ./default.nix {
        pkgs = pkgs.legacyPackages.${system};
      }).shell;
    });
}
