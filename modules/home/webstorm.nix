{ pkgs, ... }:
let
  fetchWithProxy = import ../../lib/fetch-with-proxy.nix { inherit pkgs; };
in
{
  home.packages = [
    (pkgs.jetbrains.webstorm.overrideAttrs (old: {
      src = fetchWithProxy old.src;
    }))
  ];
}
