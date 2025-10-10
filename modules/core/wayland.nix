{ inputs, pkgs, lib, ... }:
{
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  programs.dconf.enable = true;
  security.polkit.enable = true;

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    portalPackage =
      inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  services.desktopManager.plasma6.enable = true;
  services.desktopManager.cosmic.enable = true;

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };

    autoLogin = {
      enable = false;
      user = "k";
    };
    defaultSession = "plasma";
  };
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    extraPortals =  [
       pkgs.xdg-desktop-portal-gtk
       pkgs.kdePackages.xdg-desktop-portal-kde
    ]
    ++ lib.optional (pkgs ? xdg-desktop-portal-cosmic) pkgs.xdg-desktop-portal-cosmic;
    config = {
      common.default   = [ "gtk" ];
      hyprland.default = [ "hyprland" "gtk" ];
      kde.default      = [ "kde" "gtk" ];
      cosmic.default   = [ "cosmic" "gtk" ];
    };
  };

  environment.systemPackages = with pkgs; [
    kdePackages.kde-gtk-config
  ];
}
