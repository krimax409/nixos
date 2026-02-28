import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "discord";
  description = "Discord messenger";
  category = "communication";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ discord ];
    };
}
