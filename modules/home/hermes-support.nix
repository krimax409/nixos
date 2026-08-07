{ pkgs, ... }:
{
  # Поддержка для Hermes Desktop
  # Приложение устанавливается императивно через официальный installer
  # и обновляется через встроенный GUI updater

  # xdg.mimeApps.enable уже включён в xdg-mimes.nix

  # Убедиться что ~/.local/bin в PATH для CLI команд Hermes
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Базовые зависимости для Electron-приложений (обычно уже есть в системе)
  # Если после установки будут проблемы с запуском, добавить нужные либы сюда
  home.packages = with pkgs; [
    # Раскомментировать если понадобятся:
    # libsecret
    # libnotify
  ];
}
