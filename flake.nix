{
  description = "Wind, an Elixir WebSocket client library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        let
          beamPackages = pkgs.beamMinimal28Packages.overrideScope (
            _: prev: {
              elixir = prev.elixir_1_20;
            }
          );
        in
        {
          devShells.default = import ./nix/shell.nix { inherit pkgs beamPackages; };
          packages.default = pkgs.callPackage ./nix/package.nix { inherit beamPackages; };
        };
    };
}
