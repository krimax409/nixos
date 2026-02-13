{ pkgs, ... }:
let
  discord-proxied = pkgs.writeShellApplication {
    name = "discord-proxied";
    runtimeInputs = [ pkgs.discord ];
    text = ''
      export HTTPS_PROXY="http://127.0.0.1:1081"
      export HTTP_PROXY="http://127.0.0.1:1081"
      # локалка и loopback идут в обход прокси
      export NO_PROXY="localhost,127.0.0.1,::1,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
      exec ${pkgs.discord}/bin/discord "$@"
    '';
  };
in
{
  nixpkgs.config.allowUnfree = true;

  # Устанавливаем враппер со discord + сам discord для иконок
  home.packages = [
    discord-proxied
    pkgs.discord
  ];

  # Алиас для удобства
  programs.zsh.shellAliases.discord = "discord-proxied";

  # Desktop entry для меню приложений KDE/Hyprland
  xdg.desktopEntries.discord = {
    name = "Discord";
    genericName = "Internet Messenger";
    comment = "All-in-one voice and text chat (with proxy)";
    exec = "${discord-proxied}/bin/discord-proxied";
    icon = "discord";
    terminal = false;
    type = "Application";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    settings = {
      StartupWMClass = "discord";
      TryExec = "${discord-proxied}/bin/discord-proxied";
    };
  };
}
