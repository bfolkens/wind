{
  beamPackages,
  lib,
  pkgs,
}:

let
  mixExs = builtins.readFile ../mix.exs;
  version = lib.head (builtins.match ''.*version: "([^"]+)".*'' mixExs);

  mixNixDeps = pkgs.callPackages ./deps.nix { inherit beamPackages; };
in
beamPackages.buildMix {
  name = "wind";
  inherit version;

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../lib
      ../mix.exs
      ../mix.lock
    ];
  };

  beamDeps = builtins.attrValues mixNixDeps;
}
