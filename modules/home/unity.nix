import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "unity";
  description = "Unity game engine";
  category = "development";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ unityhub ];
    };
}
