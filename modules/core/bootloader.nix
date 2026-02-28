import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "bootloader";
  description = "GRUB/EFI bootloader and Zen kernel";
  category = "system";
  cfg =
    _cfg:
    { pkgs, ... }:
    {
      boot.loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };

        grub = {
          enable = true;
          device = "nodev";
          efiSupport = true;
          useOSProber = true;
          configurationLimit = 10;
        };
      };

      boot.kernelPackages = pkgs.linuxPackages_zen;
      boot.supportedFilesystems = [ "ntfs" ];
    };
}
