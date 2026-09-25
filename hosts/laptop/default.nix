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
  };
  boot.loader.timeout = 5;

  environment.systemPackages = with pkgs; [
    acpi
    brightnessctl
    cpupower-gui
    powertop
  ];

  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;
  services.tailscale.useRoutingFeatures = "client";

  users.users.k.hashedPassword = "$6$acIc8nnVIA178tex$DSrac/IWT4MaHfr5cXifjT4Q1CnmPxBiHlBRumJDkAGeufVtYth1zxjZPTtabcMzkzl7pvKPjFsoiyx.YJ3Rj0";

  # Аварийный вход на случай проблем с основным пользователем k.
  users.users.krim = {
    uid = 1001;
    isNormalUser = true;
    hashedPassword = "$6$dHdBN4Ewo3VWzI1D$Gsw4F0gd85JliEoY2vM11yF9se5AQxNW5oz8YkvMfd.OOj3T2w/KapcoK9O0.r2zae5U43TeBf5alfvnkdEiq1";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [ ./../../keys/desktop.pub ];
  };

  users.users.k.extraGroups = [
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
