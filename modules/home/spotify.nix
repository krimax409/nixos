import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "spotify";
  description = "Spotify music client";
  category = "media";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ spotify ];
    };
}
