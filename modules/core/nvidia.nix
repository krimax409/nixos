{ ... }:
{
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
