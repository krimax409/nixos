{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    # Возвращаем полную конфигурацию с исправлениями
    ./../../modules/core
  ];

  powerManagement.cpuFreqGovernor = "performance";
}
