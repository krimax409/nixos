{
  services = {
    gvfs.enable = true;
    gnome = {
      gcr-ssh-agent.enable = false;
      gnome-keyring.enable = false;
    };
    dbus.enable = true;
    fstrim.enable = true;
  };
  services.logind.settings = {
    Login = {
      HandlePowerKey = "ignore";
    };
  };
}
