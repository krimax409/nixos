{
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
  };

  # DDC/CI over HDMI fails with the proprietary driver's hardware I2C
  # controller (known NVIDIA bug; ddcutil docs: "Special Nvidia Driver
  # Settings"). Software I2C fixes it: monitor-brightness (win11-start-menu
  # brightness sliders) works over both DP and HDMI after this.
  boot.extraModprobeConfig = ''
    options nvidia NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100
  '';

  services.xserver.videoDrivers = [ "nvidia" ];
}
