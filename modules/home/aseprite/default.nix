import ../../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "aseprite";
  description = "Sprite editor and pixel art tool";
  category = "media";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ aseprite ];
    };
}
