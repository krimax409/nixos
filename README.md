# KDK NixOS Config

Личная конфигурация NixOS для двух машин: `desktop` и `laptop`. Основа —
Nix Flakes, Home Manager, Niri и Noctalia.

Конфигурация намеренно простая: обычные NixOS/Home Manager модули, явные
импорты и никаких собственных фабрик, профилей или скрытых зависимостей.

## Структура

```text
.
├── flake.nix                 # Входная точка и два хоста
├── configs/
│   ├── niri/                 # Общая и host-specific конфигурация Niri
│   ├── noctalia/             # База, палитры и GUI overrides Noctalia
│   └── proxy/                # Общий PAC для Chromium-браузеров
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
подключается отдельно в конфигурации каждого хоста.

## Команды

```bash
# Проверить flake
nix flake check --no-build

# Собрать конфигурацию без активации
nixos-rebuild build --flake .#desktop
nixos-rebuild build --flake .#laptop

# Подготовить desktop-конфигурацию к следующей загрузке
sudo nixos-rebuild boot --flake path:/etc/nixos/nixos-config#desktop

# Применить конфигурацию (пароль не требуется, см. «sudo и применение конфигурации»)
# nft и nfs вызывают nixos-rebuild напрямую из sudo NOPASSWD allowlist.
nft                # sudo nixos-rebuild test   --flake /etc/nixos/nixos-config
nfs                # sudo nixos-rebuild switch --flake /etc/nixos/nixos-config

# Обновить inputs
nix flake update

# Обновить inputs и сразу применить (запросит пароль)
nfu                # nh os switch --update

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

## Niri и Noctalia

Конфиги не копируются в Nix store: Home Manager создаёт out-of-store симлинки
на редактируемые файлы этого репозитория.

- `configs/niri/common.kdl` содержит общие binds, layout и window rules.
- `configs/niri/desktop.kdl` и `configs/niri/laptop.kdl` — точки входа хостов.
- `configs/noctalia/config.toml` содержит общую базу Noctalia.
- `configs/noctalia/palettes/` содержит общие пользовательские палитры.
- `configs/noctalia/<host>/settings.toml` содержит изменения из GUI для хоста.

Noctalia записывает изменения GUI через симлинк прямо в соответствующий
`settings.toml`. Общая тема и раскладка панели задаются в `config.toml`, а в
host overrides следует оставлять только различия оборудования и пользовательские
настройки конкретной машины. После изменения настроек в GUI обязательно проверьте
версионируемые файлы:

```bash
git diff -- configs/niri configs/noctalia
```

`state.toml`, история уведомлений, кэши, плагины и локальные секреты Noctalia
остаются в пользовательских XDG-каталогах и не версионируются.

## Прокси браузеров

Chrome и Brave имеют три launcher-профиля: обычный использует общий
`configs/proxy/throne.pac` с автоматическим fallback на прямое соединение.
Локальный user-сервис отдаёт PAC браузерам по `http://127.0.0.1:18765/throne.pac`,
`Proxy Only` всегда подключается через `127.0.0.1:2080`, а `Direct` полностью
обходит прокси. TUN-режим Throne отключён; правила внешних маршрутов задаются
в самом Throne. Локальные адреса PAC всегда направляет напрямую.

## sudo и применение конфигурации

`modules/core/sudo.nix` разрешает пользователю беспарольный `sudo` для
фиксированного списка команд: `nixos-rebuild`, `systemctl` и `git`. Пути указаны
через `/run/current-system/sw/bin/`, то есть содержимое меняется только вместе с
самой конфигурацией, и подменить их без root нельзя.

`nh` в этот список **не входит намеренно.** Он несовместим с allowlist по своему
устройству:

1. `nh os switch` отказывается работать под root («It will escalate its
   privileges internally as needed»), поэтому правило на сам бинарь `nh`
   недостижимо.
2. Эскалацию `nh` делает сам, и оборачивает её в `env`, чтобы протащить
   переменные окружения через границу привилегий:

   ```text
   COMMAND=/run/current-system/sw/bin/env PATH=... NH_FLAKE=... \
           /nix/store/<hash>/bin/switch-to-configuration test
   ```

   `sudo` видит здесь команду `env`, а не `switch-to-configuration`, поэтому
   правило вида `/nix/store/*/bin/switch-to-configuration` не сматчится никогда.
   А `NOPASSWD` на `env` — это беспарольный root на что угодно
   (`sudo env LD_PRELOAD=... любая_команда`), то есть строго хуже честного
   `security.sudo.wheelNeedsPassword = false`.

Поэтому `nfs` и `nft` вызывают `nixos-rebuild` напрямую — он есть в allowlist и
запускается как root без внутренней эскалации. `nh` остаётся для интерактивных
задач: `nfu` (обновление inputs) и `nc` (`nh clean`). Пароль там спрашивается
один раз на `timestamp_timeout=15` минут, что для нечастых операций нормально.

Флаг `nh --elevation-strategy passwordless` проблему не решает: он лишь
добавляет `sudo -n`, а команда под ним всё равно остаётся `env`.

## SSH

Доступ описан в `modules/core/tailscale.nix`. Аутентификация только по ключу:
`PasswordAuthentication` и `KbdInteractiveAuthentication` выключены, root-логин
запрещён.

Порт 22 **не открыт глобально.** `services.openssh.openFirewall = false`, а
доступ выдаётся через `networking.firewall.interfaces`: `tailscale0` на обеих
машинах и host-specific LAN-интерфейс (`enp8s0` на desktop, `wlp3s0` на
laptop) как аварийный путь. Laptop дополнительно слушает порт 2222 только на
`tailscale0`, чтобы обычный OpenSSH оставался доступен независимо от Tailscale
SSH на порту 22. Это важно, потому что глобальное правило открыло бы SSH и на
публичных IPv6-адресах.

Публичные ключи лежат в `keys/` и подключаются через
`users.users.<user>.openssh.authorizedKeys.keyFiles`. OpenSSH читает и
`%h/.ssh/authorized_keys`, и `/etc/ssh/authorized_keys.d/%u`, поэтому
декларативные ключи добавляются к существующим императивным, а не заменяют их.

## Особенности

- Niri и Noctalia работают нативно на Wayland; XWayland обеспечивает
  `xwayland-satellite`.
- NVIDIA включена только на desktop; laptop использует AMDGPU/Mesa.
- Steam, Gamescope, GameMode, QEMU/KVM и virt-manager включены на обеих машинах.
- Codex CLI берётся из отдельного закреплённого input `codex-nixpkgs`.
- Zed, VS Code, Unity, Neovim и инструменты разработки установлены декларативно.
- JetBrains Mono Nerd Font устанавливается из nixpkgs.
- Некоторые приложения используют локальный прокси `127.0.0.1:2080`.

Стабильные значения `system.stateVersion` и `home.stateVersion` не должны
обновляться вместе с nixpkgs: для `desktop` это `24.05`, для `laptop` — `25.11`.
