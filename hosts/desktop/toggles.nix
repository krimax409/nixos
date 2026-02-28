# Managed by kdk-tui. Manual edits preserved.
{
  kdk.profiles = {
    base.enable = true;
    gaming.enable = true;
  };

  kdk.modules = {
    flatpak.enable = true;
    virtualization.enable = true;
  };

  home-manager.users.k = {
    kdk.homeProfiles = {
      base.enable = true;
      development.enable = true;
      kde-desktop.enable = true;
    };

    kdk.home = {
      audacious.enable = true;
      browser.enable = true;
      cava.enable = true;
      claude.enable = true;
      discord.enable = true;
      flow.enable = true;
      gaming.enable = true;
      ghostty.enable = true;
      nemo.enable = true;
      nix-search.enable = true;
      obsidian.enable = true;
      packages-gui.enable = true;
      spotify.enable = true;
      superfile.enable = true;
      unity.enable = true;
      viewnior.enable = true;
    };
  };
}
