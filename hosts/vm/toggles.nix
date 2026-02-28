# Managed by kdk-tui. Manual edits preserved.
{
  kdk.profiles = {
    base.enable = true;
  };

  home-manager.users.k = {
    kdk.homeProfiles = {
      base.enable = true;
      kde-desktop.enable = true;
    };

    kdk.home = {
      browser.enable = true;
      ghostty.enable = true;
      nemo.enable = true;
      packages-gui.enable = true;
      viewnior.enable = true;
    };
  };
}
