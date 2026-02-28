import ../../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "packages-gui";
  description = "GUI apps: GIMP, OBS, VLC, etc.";
  category = "packages";

  cfg = _cfg: { pkgs, ... }: {
    home.packages = with pkgs; [
      ## Multimedia
      audacity
      gimp
      obs-studio
      pavucontrol
      soundwireserver
      video-trimmer
      vlc

      ## Communication
      telegram-desktop

      ## Office
      libreoffice
      gnome-calculator

      ## Password manager
      bitwarden-desktop

      ## Utility
      dconf-editor
      gnome-disk-utility
      mission-center # GUI resources monitor
      zenity

      ## Level editor
      ldtk
      tiled
    ];
  };
}
