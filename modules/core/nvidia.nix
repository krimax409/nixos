{
  config,
  pkgs,
  lib,
  ...
}:
{
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
  };

  hardware.graphics = {
    enable = true; # заменяет старое hardware.opengl.enable
    enable32Bit = true; # заменяет driSupport32Bit
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  nixpkgs.config.allowUnfree = true;
}
