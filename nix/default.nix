{ pkgs, ... }:

let
  beamPackages = pkgs.beamMinimal28Packages.overrideScope (
    _: prev: {
      elixir = prev.elixir_1_20;
    }
  );
in
{
  packages.default = pkgs.callPackage ./package.nix { inherit beamPackages; };

  devShells.default = pkgs.mkShell {
    packages = with beamPackages; [
      elixir
      erlang
      hex
    ];
  };
}
