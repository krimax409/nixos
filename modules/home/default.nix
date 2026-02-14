{ ... }:
{
  imports = [
    # Базовые утилиты
    ./bat.nix
    ./git.nix
    ./kitty.nix
    ./micro.nix
    ./zsh
    ./ssh.nix

    # Инструменты и мониторинг
    ./btop.nix
    ./fastfetch.nix
    ./fzf.nix
    ./gtk.nix
    ./lazygit.nix
    ./nvim.nix
    ./xdg-mimes.nix

    # Пакеты
    ./packages/cli.nix
    ./packages/dev.nix
    ./packages/gui.nix
    # ./packages/custom.nix

    # Приложения
    # ./aseprite/aseprite.nix
    ./audacious.nix
    ./browser.nix
    ./cava.nix
    ./flow.nix
    ./gnome.nix
    ./nemo.nix
    ./nix-search/nix-search.nix
    ./obsidian.nix
    ./p10k/p10k.nix
    ./scripts/scripts.nix
    ./superfile/superfile.nix

    # Игры
    ./gaming.nix
    # ./retroarch.nix

    # Терминалы
    ./ghostty.nix

    # Коммуникации и медиа
    ./discord.nix
    ./spotify.nix
    ./rider.nix

    # IDE
    ./webstorm.nix

    # Claude Code
    ./claude.nix

    # Hyprland
    ./hyprland-minimal.nix
    ./rofi.nix
    ./swaylock.nix
    ./swayosd.nix
    ./swaync/swaync.nix
    ./waybar
    ./waypaper.nix
  ];
}
