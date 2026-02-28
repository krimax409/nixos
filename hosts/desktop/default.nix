{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./toggles.nix
  ];

  powerManagement.cpuFreqGovernor = "performance";
}
