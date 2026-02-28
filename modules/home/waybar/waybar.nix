{ config, lib, ... }:
lib.mkIf config.kdk.home.waybar.enable {
  programs.waybar = {
    enable = true;
  };
}
