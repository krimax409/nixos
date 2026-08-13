{ config, lib, ... }:
# Per-app memory limits через systemd scope drop-ins.
# Работает для приложений, запущенных через desktop-entry → systemd scope.
#
# Discord/Chrome/Spotify попадают в scope вида `app-discord-<PID>.scope`.
# Drop-in `app-discord-.scope.d/limits.conf` применяется ко ВСЕМ таким scope.
#
# MemoryHigh — мягкий лимит: при превышении ядро агрессивно реклеймит память,
#              процесс тормозится, но не убивается. С zram реклейм дешёвый.
# MemoryMax  — жёсткий лимит: при превышении cgroup OOM killer убивает самый
#              тяжёлый процесс в cgroup (обычно рендерер). Discord перезагружает.
{
  xdg.configFile = {
    # Discord: main (~300 MiB) + renderer (~1-2 GiB норма, до 15 GiB утечка)
    "systemd/user/app-discord-.scope.d/limits.conf".text = ''
      [Scope]
      MemoryHigh=6G
      MemoryMax=8G
    '';

    # Chrome: каждый tab — отдельный процесс, scope для всех вместе
    # У тебя суммарно ~6 GiB, но тут только scope от launcher (остальные в app-niri-env)
    "systemd/user/app-com.google.Chrome-.scope.d/limits.conf".text = ''
      [Scope]
      MemoryHigh=4G
      MemoryMax=6G
    '';

    # Spotify: ~500 MiB норма, редко течёт
    "systemd/user/app-spotify-.scope.d/limits.conf".text = ''
      [Scope]
      MemoryHigh=2G
      MemoryMax=3G
    '';
  };

  # Перезагрузить systemd после изменения drop-in
  home.activation.reloadSystemdUser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${config.systemd.user.systemctlPath} --user daemon-reload
  '';
}
