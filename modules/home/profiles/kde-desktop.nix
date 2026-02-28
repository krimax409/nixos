import ../../../lib/mkProfile.nix {
  namespace = "kdk.homeProfiles";
  modulesNamespace = "kdk.home";
  name = "kde-desktop";
  description = "KDE Plasma 6 desktop environment";
  modules = [
    "plasma"
    "gnome"
  ];
}
