# Исправление packaging `modules/home/fractal.nix`

## Ревизия предыдущего ревью

Проверка на живой системе не подтвердила половину моих же замечаний.

| Замечание | Вердикт | Обоснование |
|---|---|---|
| `pythonImportsCheck` сломан | **Снято** | Каталоги модулей называются буквально `fractal` и `wiki` (`.../site-packages/fractal`). Проверка корректна. Мой тест использовал системный `python3`, который по устройству `buildPythonApplication` эти модули не видит никогда. |
| `pkgs.tmux` попал случайно | **Инвертировано** | `tmux` — настоящая runtime-зависимость: есть `fractal/util/tmux.py`, 49 вызовов `tmux` в `_scripts/*.sh`. Удалять нельзя. |
| Нет upstream-ссылок | **Подтверждено** | Комментариев и ссылок на репозиторий нет. |
| Версии могли устареть | **Снято** | 1.1.0 и 1.2.0 — актуальные на PyPI. |

Моё исходное предложение «вынести `tmux` в `cli.nix`» сломало бы `fractal` в рантайме.

## Настоящая проблема

`fractal` и `wiki` вызывают внешние утилиты по короткому имени, через PATH:

- `fractal/util/tmux.py:42` — `['tmux', *server, 'list-sessions', ...]`
- `_scripts/*.sh` — 137 вызовов `git`, 49 `tmux`
- `wiki/cli/utils.py`, `wiki/cli/cmd/wiki.py` — `['git', ...]`

При этом в замыкании самих derivation этих утилит нет:

```
nix-store -qR <plasma-fractal-1.1.0> | grep -i tmux   → пусто
```

Работает всё по случайности:

- `tmux` есть в PATH **только** из-за строки `pkgs.tmux` в `home.packages` этого же файла — неявная связь, ничем не задокументированная
- `git` не объявлен зависимостью вообще, а приходит из `modules/core/system.nix:23`

Итог: правка `home.packages` в другом файле молча ломает `fractal`. Именно в эту ловушку попало моё первое ревью.

`Requires-Dist` в METADATA перечисляет только Python-пакеты (`plasma-wiki`, `rich`, `textual`, `typer`) — про `tmux`/`git` upstream не сообщает, поэтому Nix их и не подтянул.

## Что делать

### 1. Сделать derivation самодостаточными (`makeWrapper`)

Прописать PATH внутрь обёрток, чтобы CLI не зависел от профиля пользователя:

```nix
nativeBuildInputs = [ pkgs.makeWrapper ];

# fractal вызывает tmux и git по короткому имени (fractal/util/tmux.py,
# _scripts/*.sh). Инжектим их, чтобы CLI не зависел от PATH пользователя.
postFixup = ''
  wrapProgram $out/bin/fractal \
    --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.tmux pkgs.git pkgs.bash ]}
'';
```

Для `plasmaWiki` — то же, но только с `pkgs.git`.

`pkgs.bash` нужен потому, что шелл-скрипты лежат внутри `site-packages` (не в `bin/`), поэтому `patchShebangs` их `#!/usr/bin/env bash` не трогает — проверить это отдельно после сборки.

### 2. Вернуть `tmux` в интерактивный PATH осознанно

После шага 1 `tmux` уедет в замыкание `fractal` и пропадёт из пользовательского PATH. Он там был, так что чтобы не менять поведение — перенести `pkgs.tmux` в `modules/home/packages/cli.nix`, где ему и место семантически.

Тогда `fractal.nix` содержит только то, что относится к fractal/wiki, но уже без скрытой связи: derivation самодостаточен, а `tmux` в `cli.nix` — независимое решение «хочу tmux в шелле».

### 3. Добавить upstream-ссылки

```nix
# https://github.com/plasma-ai/fractal
# Changelog: https://github.com/plasma-ai/fractal/blob/main/CHANGELOG.md
version = "1.1.0"; # актуальная на PyPI 2026-08-07
```

## Проверка

```bash
nixos-rebuild build --flake .#desktop

# tmux и git должны быть в замыкании
nix-store -qR ./result | grep -E 'tmux|git-[0-9]' | head

# обёртка должна прописывать PATH
grep -o 'PATH.*' $(readlink -f result/...)/bin/fractal | head -3
```

Затем `nfs` и функциональная проверка:

```bash
fractal --help && wiki --help
env -i $(command -v fractal) --help   # без tmux/git в PATH — не должно падать
```

Последняя проверка — главная: именно она отличает исправленное состояние от текущего.

## Порядок

1. `modules/home/fractal.nix` — `makeWrapper` + `postFixup` для обоих пакетов, upstream-комментарии, убрать `pkgs.tmux`
2. `modules/home/packages/cli.nix` — добавить `tmux`
3. `nixos-rebuild build`, проверить замыкание и обёртку
4. `nfs`, прогнать функциональные проверки

## Замечания вне объёма

- `fractal install` и `wiki install` пишут skills в `~/.claude/skills/` императивно (сейчас там `karpathy-guidelines`) — вне Nix, при переустановке не восстановится. Отдельная задача, если нужна декларативность.
- Оба пакета есть только на PyPI; при мажорном обновлении hash в `fetchPypi` придётся обновлять руками — та же хрупкость, что задокументирована для Discord.
