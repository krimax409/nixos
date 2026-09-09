{
  services = {
    gvfs.enable = true;
    gnome = {
      gcr-ssh-agent.enable = false;
      gnome-keyring.enable = true;
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
