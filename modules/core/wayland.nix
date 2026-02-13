{
  inputs,
  pkgs,
  lib,
  ...
}:
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

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };

    # Автологин без пароля
    autoLogin = {
      enable = true;
      user = "k";
    };

    # Читаем сессию из переменной окружения, по умолчанию Hyprland
    defaultSession =
      let
        envSession = builtins.getEnv "NIXOS_DEFAULT_SESSION";
      in
      if envSession != "" then envSession else "hyprland";
  };
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    config = {
      common.default = [ "gtk" ];
      hyprland.default = [
        "hyprland"
        "gtk"
      ];
      kde.default = [
        "kde"
        "gtk"
      ];
    };
  };

  environment.systemPackages = with pkgs; [ kdePackages.kde-gtk-config ];
}
