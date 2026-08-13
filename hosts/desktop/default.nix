{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./../../modules/core/bootloader.nix
    ./../../modules/core/nvidia.nix
    ./../../modules/core/virtualization.nix
  ];

  boot.loader = {
    timeout = 5;

    limine = {
      enable = true;
      maxGenerations = 10;
      panicOnChecksumMismatch = true;
      secureBoot.enable = true;

      extraEntries = ''
        /Windows 11
          protocol: efi
          path: guid(931e04c1-094e-4c56-a9e4-3813c065e245):/EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };

  environment.systemPackages = [ pkgs.sbctl ];

  powerManagement.cpuFreqGovernor = "performance";
}
