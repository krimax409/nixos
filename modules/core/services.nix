import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "services";
  description = "System services: gvfs, keyring, D-Bus";
  category = "system";
  cfg =
    _cfg:
    { pkgs, ... }:
    {
      services = {
        gvfs.enable = true;
        gnome = {
          tinysparql.enable = true;
          gnome-keyring.enable = true;
        };
        dbus.enable = true;
        fstrim.enable = true;

        dbus.packages = with pkgs; [
          gcr
          gnome-settings-daemon
        ];
      };
      services.logind.settings = {
        Login = {
          HandlePowerKey = "ignore";
        };
      };
    };
}
