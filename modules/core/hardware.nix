import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "hardware";
  description = "Graphics drivers and firmware";
  category = "hardware";
  cfg =
    _cfg:
    { pkgs, ... }:
    {
      hardware = {
        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            libva-vdpau-driver
            libvdpau-va-gl
          ];
        };
        enableRedistributableFirmware = true;
      };
    };
}
