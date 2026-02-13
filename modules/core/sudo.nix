{ username, ... }:
{
  # Настройка sudo для удобной работы с системой
  security.sudo = {
    enable = true;

    extraRules = [
      {
        users = [ username ];
        commands = [
          # NixOS rebuild команды
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nh";
            options = [ "NOPASSWD" ];
          }
          # Git команды для коммитов (если нужно)
          {
            command = "/run/current-system/sw/bin/git";
            options = [ "NOPASSWD" ];
          }
          # Systemctl для управления сервисами
          {
            command = "/run/current-system/sw/bin/systemctl";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Дополнительные настройки безопасности
    extraConfig = ''
      # Сохранять переменные окружения при sudo
      Defaults env_keep += "LOCALE_ARCHIVE"
      Defaults env_keep += "NIXOS_INSTALL_BOOTLOADER"

      # Увеличить таймаут (15 минут вместо 5)
      Defaults timestamp_timeout=15

      # Не запрашивать пароль для wheel группы при выполнении разрешенных команд
      %wheel ALL=(ALL:ALL) NOPASSWD: /run/current-system/sw/bin/nixos-rebuild, /run/current-system/sw/bin/nh, /run/current-system/sw/bin/systemctl
    '';
  };
}
