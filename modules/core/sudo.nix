import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "sudo";
  description = "Passwordless sudo for system commands";
  category = "system";
  cfg =
    _cfg:
    { username, ... }:
    {
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
                command = "/run/current-system/sw/bin/nh";
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
          %wheel ALL=(ALL:ALL) NOPASSWD: /run/current-system/sw/bin/nixos-rebuild, /run/current-system/sw/bin/nh, /run/current-system/sw/bin/systemctl
        '';
      };
    };
}
