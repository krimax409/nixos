import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "xserver";
  description = "X11 server with keyboard layout";
  category = "desktop";
  cfg =
    _cfg:
    { ... }:
    {
      services = {
        xserver = {
          enable = true;
          xkb.layout = "us,ru";
          xkb.options = "grp:alt_space_toggle";
        };

        libinput = {
          enable = true;
        };
      };
      systemd.settings.Manager = {
        DefaultTimeoutStopSec = "10s";
      };
    };
}
