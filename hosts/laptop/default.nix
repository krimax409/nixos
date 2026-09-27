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

  # Password hashes live in secrets/passwords.yaml (sops+age, encrypted in the
  # public repo). PIN-style password is only safe as long as the hash never
  # leaks into git — do NOT put hashedPassword inline again.
  sops.secrets.passwords-k = {
    sopsFile = ../../secrets/passwords.yaml;
    key = "k";
    neededForUsers = true;
  };
  sops.secrets.passwords-root = {
    sopsFile = ../../secrets/passwords.yaml;
    key = "root";
    neededForUsers = true;
  };
  users.users.k.hashedPasswordFile = config.sops.secrets.passwords-k.path;

  # Emergency login path: root with the same password as k, for TTY/rescue.
  users.users.root.hashedPasswordFile = config.sops.secrets.passwords-root.path;

  # Пароли применяются из конфига при каждой активации, иначе hashedPassword
  # срабатывает только на создании юзера (mutableUsers по умолчанию true).
  users.mutableUsers = false;

  # Одноразовая миграция: чекаут репозитория живёт в ~/nixos (у desktop —
  # ~/src/nixos-config). Переносит как старый чекаут /etc/nixos, так и
  # прежнее расположение /home/k/src/nixos-config. Срабатывает только если
  # /etc/nixos — сам чекаут (есть .git, нет nixos-config внутри).
  # Симлинк /etc/nixos/nixos-config создаёт modules/core/nixos-config-link.nix.
  system.activationScripts.nixos-config-home = ''
    if [ -d /etc/nixos ] && [ ! -L /etc/nixos ] && [ -d /etc/nixos/.git ] && [ ! -e /etc/nixos/nixos-config ]; then
      mv /etc/nixos /home/k/nixos
      chown -R 1000:100 /home/k/nixos
    elif [ -d /home/k/src/nixos-config ] && [ ! -L /home/k/src/nixos-config ]; then
      mv /home/k/src/nixos-config /home/k/nixos
      chown -R 1000:100 /home/k/nixos
      rmdir /home/k/src 2>/dev/null || true
    fi
  '';

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
