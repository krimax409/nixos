{ pkgs, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./wwan.nix
    ./../../modules/core
    ./../../modules/core/bootloader.nix
    ./../../modules/core/virtualization.nix
  ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;
    extraInstallCommands = ''
      # EFI menu settings override loader.conf; keep the configured timeout authoritative.
      ${config.systemd.package}/bin/bootctl set-timeout ""
    '';
  };
  boot.loader.timeout = 0;

  environment.systemPackages = with pkgs; [
    acpi
    brightnessctl
    cpupower-gui
    powertop
  ];

  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;
  services.tailscale.useRoutingFeatures = "client";

  users.users.krim.extraGroups = [
    "input"
    "gamemode"
  ];

  services = {
    printing.enable = true;
    upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "PowerOff";
    };

    tlp.settings = {
      CPU_ENERGY_PERF_POLICY_ON_AC = "power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 1;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "performance";
    };
  };

  powerManagement.cpuFreqGovernor = "performance";

  boot = {
    kernelModules = [ "acpi_call" ];
    extraModulePackages = with config.boot.kernelPackages; [
      acpi_call
      cpupower
    ];
  };
}
