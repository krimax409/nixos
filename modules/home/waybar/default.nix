{ config, lib, ... }:
{
  imports = [
    ./waybar.nix
    ./settings.nix
    ./style.nix
  ];

  options.kdk.home.waybar = {
    enable = lib.mkEnableOption "the waybar module";
  };

  config.kdk.meta.modules."kdk.home.waybar" = {
    name = "waybar";
    namespace = "kdk.home";
    description = "Wayland status bar";
    category = "desktop";
    deps = [ ];
    enabled = config.kdk.home.waybar.enable;
  };
}
