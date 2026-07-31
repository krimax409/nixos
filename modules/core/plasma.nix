{ pkgs, username, ... }:
{
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  security.polkit.enable = true;

  services.desktopManager.plasma6.enable = true;

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    autoLogin = {
      enable = true;
      user = username;
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kate
  ];
}
