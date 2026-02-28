# KDK NixOS Config

Модульная конфигурация NixOS на базе Nix Flakes с Hyprland и Gruvbox Dark Hard темой. Форк [Frost-Phoenix/nixos-config](https://github.com/Frost-Phoenix/nixos-config), переработанный для максимальной модульности — каждый модуль включается/отключается одной строкой, зависимости разрешаются автоматически.

## Стек

| Компонент | Технология |
|-----------|-----------|
| Window Manager | Hyprland (Wayland) |
| Bar | Waybar |
| Terminal | Ghostty / Kitty |
| Shell | Zsh + Powerlevel10k |
| Editor | Neovim / VSCode |
| Launcher | Rofi |
| Theme | Gruvbox Dark Hard |
| Audio | PipeWire |
| Fonts | Maple Mono + Nerd Fonts |
| Lock Screen | Hyprlock / Swaylock |

## Структура

```
.
├── flake.nix                     # Точка входа, 3 хоста: desktop, laptop, vm
├── lib/
│   ├── mkModule.nix              # Фабрика модулей (enable, deps, meta)
│   ├── mkProfile.nix             # Фабрика профилей (группы модулей)
│   ├── importDir.nix             # Авто-импорт .nix файлов из директории
│   └── metaOptions.nix           # Типы для реестра метаданных
├── hosts/
│   ├── desktop/
│   │   ├── default.nix           # Hardware-specific конфиг
│   │   ├── toggles.nix           # Включённые модули и профили
│   │   └── hardware-configuration.nix
│   ├── laptop/                   # Аналогично + TLP, power management
│   └── vm/                       # Минимальная конфигурация для VM
├── modules/
│   ├── core/                     # Системные NixOS-модули (17 шт.)
│   │   ├── default.nix           # Авто-импорт через importDir
│   │   ├── meta.nix              # Реестр метаданных (kdk.meta)
│   │   ├── user.nix              # Home Manager + пользователь
│   │   ├── profiles/
│   │   │   ├── base.nix          # 13 базовых модулей
│   │   │   └── gaming.nix        # Steam + NVIDIA
│   │   ├── bootloader.nix, hardware.nix, network.nix, ...
│   │   └── steam.nix, nvidia.nix, wayland.nix, ...
│   └── home/                     # Home Manager модули (46 шт.)
│       ├── default.nix           # Авто-импорт через importDir
│       ├── meta.nix              # HM-level метаданные
│       ├── profiles/
│       │   ├── base.nix          # Shell, editors, CLI
│       │   ├── development.nix   # IDEs, git, dev tools
│       │   └── hyprland-desktop.nix  # Hyprland + waybar + rofi + ...
│       ├── discord.nix, browser.nix, spotify.nix, ...
│       ├── waybar/               # Multi-file: default + settings + style
│       ├── zsh/                  # Multi-file: default + aliases + keybinds
│       └── packages/             # CLI, GUI, dev, custom пакеты
├── pkgs/                         # Кастомные пакеты (сборка из исходников)
└── wallpapers/                   # Обои
```

## Архитектура модулей

### Namespace `kdk`

Все опции живут в пространстве `kdk`:

```
kdk.modules.*        — системные модули (core)
kdk.profiles.*       — системные профили
kdk.home.*           — пользовательские модули (home-manager)
kdk.homeProfiles.*   — пользовательские профили
kdk.meta             — реестр метаданных (read-only)
```

### mkModule — фабрика модулей

Каждый модуль — один вызов `mkModule`:

```nix
# modules/core/steam.nix
import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "steam";
  description = "Steam with Proton-GE and GameScope";
  category = "gaming";
  deps = [ "nvidia" ];  # автоматически включит nvidia

  cfg = _cfg: { pkgs, ... }: {
    programs.steam.enable = true;
    # ...
  };
}
```

Модуль получает:
- `kdk.modules.steam.enable` — toggle (default: false)
- Автоматическое включение зависимостей (`nvidia`)
- Регистрацию в `kdk.meta` для TUI-discovery

### mkProfile — группы модулей

```nix
# modules/core/profiles/gaming.nix
import ../../../lib/mkProfile.nix {
  namespace = "kdk.profiles";
  modulesNamespace = "kdk.modules";
  name = "gaming";
  description = "NVIDIA GPU and Steam gaming";
  modules = [ "steam" "nvidia" ];
}
```

### Конфигурация хоста

Каждый хост состоит из двух файлов:

**`default.nix`** — hardware-specific настройки (power management, boot, etc.)

**`toggles.nix`** — какие модули включены (управляется вручную или TUI):

```nix
# hosts/desktop/toggles.nix
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
      hyprland-desktop.enable = true;
      development.enable = true;
    };
    kdk.home = {
      discord.enable = true;
      browser.enable = true;
      spotify.enable = true;
      # ...
    };
  };
}
```

### Авто-импорт

`importDir` сканирует директорию и импортирует все `.nix` файлы (кроме `default.nix`) и поддиректории с `default.nix`. Добавил новый файл — он автоматически доступен как модуль.

### Реестр метаданных (kdk.meta)

Каждый модуль и профиль регистрирует себя в `kdk.meta`. Запрос всех метаданных:

```bash
nix eval .#nixosConfigurations.desktop.config.kdk.meta --json
```

Возвращает JSON:

```json
{
  "modules": {
    "kdk.modules.steam": {
      "name": "steam",
      "namespace": "kdk.modules",
      "description": "Steam with Proton-GE and GameScope",
      "category": "gaming",
      "deps": ["nvidia"],
      "enabled": true
    },
    "kdk.home.discord": {
      "name": "discord",
      "namespace": "kdk.home",
      "description": "Discord messenger",
      "category": "communication",
      "deps": [],
      "enabled": true
    }
  },
  "profiles": {
    "kdk.profiles.gaming": {
      "name": "gaming",
      "namespace": "kdk.profiles",
      "description": "NVIDIA GPU and Steam gaming",
      "modules": ["steam", "nvidia"],
      "enabled": true
    }
  }
}
```

## TUI (планируется)

Архитектура подготовлена для TUI-приложения для управления модулями:

1. **Discovery** — `nix eval .#nixosConfigurations.<host>.config.kdk.meta --json` возвращает полный граф модулей, профилей, зависимостей и enabled-статусов
2. **Toggle** — TUI парсит и перезаписывает `hosts/<host>/toggles.nix` (формат строгий: одна строка = один toggle)
3. **Apply** — `sudo nh os switch` / `sudo nh os test`

Категории модулей для группировки в TUI:

| Категория | Описание |
|-----------|----------|
| `system` | Загрузчик, настройки Nix, сеть, sudo, сервисы |
| `hardware` | GPU драйверы, аудио, прошивки |
| `desktop` | Hyprland, Waybar, Rofi, GTK темы |
| `terminal` | Терминалы, shell, CLI утилиты |
| `development` | Git, IDE, редакторы |
| `communication` | Discord, мессенджеры |
| `media` | Аудио/видео плееры, просмотрщики |
| `gaming` | Steam, эмуляторы |
| `utility` | Файловые менеджеры, разное |
| `packages` | Бандлы пакетов (CLI, GUI, dev) |

## Команды

```bash
# Тест конфигурации (без переключения)
nh os test                    # или: nix-test

# Применить конфигурацию
nh os switch                  # или: nix-switch

# Обновить flake inputs и применить
nh os switch --update         # или: nix-update

# Очистить старые поколения
nh clean all --keep 5         # или: nix-clean

# Форматирование кода
treefmt

# Запросить метаданные модулей
nix eval .#nixosConfigurations.desktop.config.kdk.meta --json | python3 -m json.tool
```

## Хосты

| Хост | Описание |
|------|----------|
| `desktop` | Десктоп, performance governor, NVIDIA, все модули |
| `laptop` | Ноутбук, TLP power management, gaming profile |
| `vm` | VM, минимальный набор, GRUB, SSH |

## Добавление нового модуля

1. Создать файл в `modules/core/` или `modules/home/`:

```nix
import ../../lib/mkModule.nix {
  namespace = "kdk.home";  # или "kdk.modules" для системного
  name = "myapp";
  description = "My application";
  category = "utility";
  deps = [ ];  # зависимости от других модулей

  cfg = _cfg: { pkgs, ... }: {
    home.packages = [ pkgs.myapp ];
  };
}
```

2. Файл автоматически подхватится через `importDir`

3. Включить в `hosts/<host>/toggles.nix`:
```nix
kdk.home.myapp.enable = true;
```

4. Применить: `nh os test`

## Credits

Форк [Frost-Phoenix/nixos-config](https://github.com/Frost-Phoenix/nixos-config). Модульная система `kdk` разработана с нуля.
