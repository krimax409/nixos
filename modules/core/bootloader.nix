{ pkgs, ... }:
{
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.supportedFilesystems = [ "ntfs" ];
}
