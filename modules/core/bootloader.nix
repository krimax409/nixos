{ pkgs, ... }:
{
  # GRUB bootloader with multi-OS support
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    grub = {
      enable = true;
      device = "nodev"; # For UEFI systems
      efiSupport = true;
      useOSProber = true; # Automatically detect other operating systems
      configurationLimit = 10;

      # Optional: customize GRUB appearance
      # theme = pkgs.nixos-grub2-theme;
      # splashImage = null;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.supportedFilesystems = [ "ntfs" ];
}
