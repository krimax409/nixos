{ username, ... }:
{
  # TODO: КРИТИЧЕСКАЯ ПРОБЛЕМА БЕЗОПАСНОСТИ
  # sudo -l показывает: (ALL : ALL) SETENV: ALL
  # Это позволяет выполнить: sudo env LD_PRELOAD=/tmp/evil.so любая_команда
  # и получить root с произвольным кодом, обходя весь NOPASSWD allowlist.
  #
  # Причина: вероятно дефолт NixOS или wheelNeedsPassword = false где-то включён.
  #
  # Исправление требует:
  # 1. security.sudo.execWheelOnly = true;
  # 2. security.sudo.wheelNeedsPassword = true; (но это сломает алиасы nfs/nft)
  # 3. Или перенести nfs/nft на doas/polkit с более точным контролем.
  #
  # До исправления считать что любой локальный процесс == потенциальный root.

  security.sudo = {
    enable = true;

    extraRules = [
      {
        users = [ username ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/git";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    extraConfig = ''
      Defaults env_keep += "LOCALE_ARCHIVE"
      Defaults env_keep += "NIXOS_INSTALL_BOOTLOADER"
      Defaults timestamp_timeout=15
      %wheel ALL=(ALL:ALL) NOPASSWD: /run/current-system/sw/bin/nixos-rebuild, /run/current-system/sw/bin/systemctl
    '';
  };
}
