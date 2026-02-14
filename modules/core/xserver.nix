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
  # To prevent getting stuck at shutdown
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };
}
