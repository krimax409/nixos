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
}
