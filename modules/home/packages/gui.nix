{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## AI coding
    opencode-desktop

    ## Multimedia
    audacity
    gimp
    obs-studio
    pavucontrol
    soundwireserver
    video-trimmer

    ## Communication
    telegram-desktop

    ## Office
    libreoffice

    ## Password manager
    bitwarden-desktop

    ## Utility
    gnome-disk-utility
    zenity

    ## Level editor
    ldtk
    tiled
  ];
}
