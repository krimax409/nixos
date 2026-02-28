import ../../../lib/mkProfile.nix {
  namespace = "kdk.homeProfiles";
  modulesNamespace = "kdk.home";
  name = "hyprland-desktop";
  description = "Hyprland desktop environment";
  modules = [
    "hyprland"
    "waybar"
    "rofi"
    "swaylock"
    "swayosd"
    "swaync"
    "waypaper"
  ];
}
