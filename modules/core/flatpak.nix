import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "flatpak";
  description = "Flatpak package manager support";
  category = "system";
  cfg =
    _cfg:
    { ... }:
    {
      services.flatpak.enable = true;
    };
}
