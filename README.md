# KDK NixOS Config

Личная конфигурация NixOS для двух машин: `desktop` и `laptop`. Основа —
Nix Flakes, Home Manager, KDE Plasma 6 и plasma-manager.

Конфигурация намеренно простая: обычные NixOS/Home Manager модули, явные
импорты и никаких собственных фабрик, профилей или скрытых зависимостей.

## Структура

```text
.
├── flake.nix                 # Входная точка и два хоста
├── hosts/
│   ├── desktop/              # Desktop hardware и настройки
│   └── laptop/               # Laptop hardware и энергосбережение
├── modules/
│   ├── core/                 # Системные NixOS-модули
│   └── home/                 # Home Manager и приложения
│       ├── packages/         # CLI, GUI и dev-пакеты
│       ├── scripts/          # Пользовательские скрипты
│       └── zsh/              # Zsh, aliases и keybindings
└── wallpapers/wallpaper.png # Текущие обои
```

Список общих системных модулей находится в `modules/core/default.nix`, список
пользовательских модулей — в `modules/home/default.nix`. Виртуализация
подключается отдельно только для desktop.

## Команды

```bash
# Проверить flake
nix flake check --no-build

# Собрать конфигурацию без активации
nixos-rebuild build --flake .#desktop
nixos-rebuild build --flake .#laptop

# Применить текущую desktop-конфигурацию
sudo nixos-rebuild switch --flake .#desktop

# То же через nh
nh os test
nh os switch

# Обновить inputs
nix flake update

# Форматировать Nix и shell-файлы
treefmt
```

## Добавление программы

Для простого пакета добавьте его в один из файлов `modules/home/packages/`.
Для программы с настройками создайте обычный Home Manager модуль:

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.example ];
}
```

Затем явно добавьте файл в `imports` внутри `modules/home/default.nix`.

## Особенности

- KDE Plasma на Wayland с декларативной настройкой через plasma-manager.
- NVIDIA, Steam, Gamescope и GameMode включены на обеих машинах.
- QEMU/KVM и virt-manager включены только на desktop.
- Codex CLI берётся из отдельного закреплённого input `codex-nixpkgs`.
- Zed, VS Code, Unity, Neovim и инструменты разработки установлены декларативно.
- JetBrains Mono Nerd Font устанавливается из nixpkgs.
- Некоторые приложения используют локальный прокси `127.0.0.1:2080`.

Стабильные значения `system.stateVersion` и `home.stateVersion` остаются
`24.05` и не должны обновляться вместе с nixpkgs.
