{ pkgs, beamPackages }:

pkgs.mkShell {
  packages = with beamPackages; [
    elixir
    erlang
    hex
    rebar3
  ];

  env.MIX_REBAR3 = "${beamPackages.rebar3}/bin/rebar3";
}
