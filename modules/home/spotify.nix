{ pkgs, ... }:
let
  spotify-proxied = pkgs.writeShellApplication {
    name = "spotify-proxied";
    runtimeInputs = [ pkgs.spotify ];
    text = ''
      export HTTPS_PROXY="http://127.0.0.1:1081"
      export HTTP_PROXY="http://127.0.0.1:1081"
      # локалка и loopback идут в обход прокси
      export NO_PROXY="localhost,127.0.0.1,::1,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
      exec ${pkgs.spotify}/bin/spotify "$@"
    '';
  };
in
{
  nixpkgs.config.allowUnfree = true;

  # Устанавливаем враппер со spotify + сам spotify для иконок
  home.packages = [
    spotify-proxied
    pkgs.spotify
  ];

  # Алиас для удобства
  programs.zsh.shellAliases.spotify = "spotify-proxied";

  # Desktop entry для меню приложений KDE/Hyprland
  xdg.desktopEntries.spotify = {
    name = "Spotify";
    genericName = "Music Player";
    comment = "Listen to music using Spotify (with proxy)";
    exec = "${spotify-proxied}/bin/spotify-proxied %U";
    icon = "spotify-client";
    terminal = false;
    type = "Application";
    categories = [
      "Audio"
      "Music"
      "Player"
      "AudioVideo"
    ];
    mimeType = [ "x-scheme-handler/spotify" ];
    settings = {
      StartupWMClass = "spotify";
      TryExec = "${spotify-proxied}/bin/spotify-proxied";
    };
  };
}
