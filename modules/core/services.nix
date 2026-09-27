{
  services = {
    gvfs.enable = true;
    gnome = {
      gcr-ssh-agent.enable = false;
      # Replaced by KeePassXC (modules/home/keepassxc.nix). gnome-keyring's
      # Login keyring stays locked on greetd autologin (no pam_gnome_keyring
      # hook) and there is no GUI prompter under niri, so apps calling
      # org.freedesktop.secrets would block forever — this is what hung
      # Chromium's os_crypt and stalled every page load (2026-09-26).
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
