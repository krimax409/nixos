{ config, pkgs, ... }:
let
  # Тайнет-адреса (100.64.0.0/10) и *.ts.net должны идти напрямую через
  # tailscale0 — прокси Throne отдаёт на них 502. Совпадает со списком в
  # modules/home/zsh/zsh_alias.nix.
  noProxy = "localhost,127.0.0.1,::1,100.64.0.0/10,.ts.net";

  home = config.home.homeDirectory;
  packagedApp = "${home}/.hermes/hermes-agent/apps/desktop/release/linux-unpacked/Hermes";

  # Двухшаговый запуск вместо простого `hermes desktop`.
  #
  # `hermes desktop` перед запуском безусловно требует, чтобы локальный
  # chrome-sandbox в ~/.hermes имел root:root 4755, пробует поправить это через
  # sudo и без TTY выходит с sys.exit(1) — из меню приложение просто не
  # стартует (_desktop_linux_sandbox_fixup в hermes_cli/main.py). Обойти это
  # можно было бы через ELECTRON_DISABLE_SANDBOX=1, но тогда renderer-процессы
  # остаются без изоляции.
  #
  # Поэтому: сначала `--build-only` (он возвращается ДО проверки sandbox, так
  # что пересборка после `hermes update` и установка иконок сохраняются), затем
  # напрямую упакованный Electron с CHROME_DEVEL_SANDBOX на неизменяемый хелпер
  # из store. Проверено: Electron принимает хелпер от новее собранного Chromium
  # и поднимает zygote с песочницей.
  hermesDesktop = pkgs.writeShellScript "hermes-desktop-launch" ''
    export NO_PROXY='${noProxy}'
    export no_proxy='${noProxy}'
    export CHROME_DEVEL_SANDBOX=/run/wrappers/bin/__chromium-suid-sandbox

    # Пересборка не должна мешать запуску: если она упала, всё равно пробуем
    # поднять уже собранный артефакт.
    '${home}/.local/bin/hermes' desktop --build-only || true

    if [ ! -x '${packagedApp}' ]; then
      exec '${home}/.local/bin/hermes' desktop
    fi
    cd '${home}/.hermes/hermes-agent/apps/desktop'
    exec '${packagedApp}' "$@"
  '';
  hermesLaunch = "${hermesDesktop}";
in
{
  # Поддержка Hermes Desktop.
  #
  # Само приложение живёт вне Nix store: installer кладёт его в ~/.hermes, а
  # обновления идут через `hermes update` (git pull + пересборка Electron), то
  # есть чекаут должен оставаться mutable. Nix отвечает только за окружение.
  #
  # xdg.mimeApps.enable уже включён в xdg-mimes.nix

  # CLI-обёртки Hermes (hermes, hermes-agent, hermes-acp) ставятся в
  # ~/.local/bin. Именно обёртка, а не сам ~/.hermes/hermes-agent/hermes,
  # вызывает python из venv — без неё запуск падает на ModuleNotFoundError.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Launcher entry держим декларативно, хотя Hermes умеет ставить его сам
  # (hermes_cli/linux_desktop_entry.py). Свой вариант нужен по трём причинам:
  #
  # 1. CHROME_DEVEL_SANDBOX. После каждой пересборки Electron
  #    (`hermes update`) собственный chrome-sandbox в ~/.hermes теряет
  #    root:root 4755, и Hermes пытается вернуть их через sudo. Из меню
  #    приложений TTY нет, пароль спросить негде — запуск обрывается на
  #    sys.exit(1). Встроенный фолбэк на --no-sandbox не срабатывает: он
  #    смотрит на /proc/sys/kernel/apparmor_restrict_unprivileged_userns,
  #    которого на NixOS не существует (_desktop_linux_needs_no_sandbox в
  #    hermes_cli/main.py). Вместо отключения песочницы даём Electron
  #    неизменяемый хелпер из store — его ставит
  #    security.chromiumSuidSandbox (modules/core/security.nix).
  #
  # 2. no_proxy. Прокси Throne на 127.0.0.1:2080 отвечает 502 на адреса
  #    тайнета, а бэкенд Hermes живёт на hermes-vm (100.89.235.11:9119).
  #    Из лаунчера переменных прокси нет, но Hermes запускают и из терминала,
  #    где они унаследованы от алиасов, — тогда boot падает на «Could not
  #    reach the remote Hermes gateway while refreshing its WebSocket ticket».
  #    Держим исключения и здесь, чтобы поведение не зависело от способа
  #    запуска (парный список — в modules/home/zsh/zsh_alias.nix).
  #
  # 3. Exec на ~/.local/bin/hermes. Генератор Hermes может записать сюда путь
  #    к venv-скрипту или к самому Python-файлу; второй из меню не работает.
  #
  # Пишем именно через home.file, а не xdg.desktopEntries: с
  # home-manager.useUserPackages записи из xdg.desktopEntries попадают в
  # /etc/profiles/per-user/k/share/applications, а Hermes пишет свою в
  # ~/.local/share/applications — и та перекрывает профиль, потому что
  # XDG_DATA_HOME идёт раньше XDG_DATA_DIRS. home.file занимает этот путь
  # read-only симлинком на store, так что генератор Hermes до него не
  # дотянется: install_desktop_entry на OSError возвращает None и запуск не
  # ломает (hermes_cli/linux_desktop_entry.py).
  home.file.".local/share/applications/hermes.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Hermes
    GenericName=Hermes Desktop
    Comment=Launch Hermes Desktop
    Exec=${hermesLaunch}
    Icon=${config.home.homeDirectory}/.hermes/hermes-agent/apps/desktop/assets/icon.png
    Terminal=false
    Categories=Utility;
    StartupNotify=true
    StartupWMClass=Hermes
  '';
}
