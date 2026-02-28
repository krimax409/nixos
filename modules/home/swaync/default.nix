import ../../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "swaync";
  description = "Notification center";
  category = "desktop";
  deps = [ "hyprland" ];

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ swaynotificationcenter ];
      xdg.configFile."swaync/style.css".source = ./style.css;
      xdg.configFile."swaync/config.json".source = ./config.json;
    };
}
