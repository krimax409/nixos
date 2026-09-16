{
  pkgs,
  username,
  ...
}:
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

    # DDC/CI monitor control (brightness sliders in win11-start-menu)
    i2c.enable = true;
  };

  environment.systemPackages = with pkgs; [ ddcutil ];
}
