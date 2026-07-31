{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./../../modules/core/virtualization.nix
  ];

  powerManagement.cpuFreqGovernor = "performance";
}
