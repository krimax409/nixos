{ pkgs, ... }:
{
  # === 1. ZRAM — сжатый своп в RAM вместо Kingston SA400 ===
  zramSwap = {
    enable = true;
    algorithm = "zstd";        # лучше сжимает Chromium/Electron (~3:1), чем lzo
    memoryPercent = 25;        # ~8 GiB из 31 → сжимается до ~24 GiB эффективно
    priority = 100;            # выше дискового свопа (sdc3 имеет priority=-1)
  };

  boot.kernel.sysctl = {
    # С zram можно свопить агрессивно — он дешёвый (RAM → zram), не SSD
    "vm.swappiness" = 180;

    # Раньше начинать прямой реклейм, не ждать нехватки памяти
    "vm.watermark_scale_factor" = 125;
    "vm.watermark_boost_factor" = 0;

    # Для zram: не читать вперёд, страницы сжаты и не на диске
    "vm.page-cluster" = 0;
  };

  # === 2. COREDUMP — не дампить гигантские Electron-процессы ===
  # 15 GiB Discord → 74 MiB/s запись на sdc → заморозка на 4+ минуты
  systemd.coredump.settings = {
    Coredump = {
      ProcessSizeMax = "1G";
      ExternalSizeMax = "1G";
      MaxUse = "2G";
      Storage = "external";
    };
  };

  # === 3. EARLYOOM — убивать утечку до заморозки ===
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;      # <5% свободной RAM
    freeSwapThreshold = 10;    # <10% свободного swap (включая zram)

    # Не трогать критичные процессы
    extraArgs = [
      "--avoid" "^(niri|kitty|sshd|systemd|gpg-agent)$"
      # Предпочитать Electron/Chromium — они обычно виноваты
      "--prefer" "^(\\.?(Discord|chrome|spotify|codex|zed)).*$"
    ];
  };

  # === 4. SYSTEMD-OOMD — убивать по memory pressure ===
  # Работает на основе PSI (Pressure Stall Information)
  systemd.oomd = {
    enableRootSlice = false;   # не трогать системные сервисы
    enableUserSlices = true;   # включить на user@.service
  };
}
