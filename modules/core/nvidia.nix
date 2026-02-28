import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "nvidia";
  description = "NVIDIA proprietary drivers";
  category = "hardware";
  cfg =
    _cfg:
    { ... }:
    {
      hardware.nvidia = {
        modesetting.enable = true;
        open = false;
      };

      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
