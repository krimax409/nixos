import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "plasma";
  description = "KDE Plasma 6 desktop and SDDM login";
  category = "desktop";
  deps = [
    "hardware"
    "xserver"
  ];

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;
      security.polkit.enable = true;

      services.desktopManager.plasma6.enable = true;

      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };

      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
      };

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa
        kate
      ];
    };
}
