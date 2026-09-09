{ pkgs, ... }:
{
  # === 1. ZRAM — основной своп, диск только как fallback ===
  zramSwap = {
    enable = true;
    algorithm = "zstd";        # хорошее сжатие при приемлемой нагрузке на CPU
    memoryPercent = 50;        # логический лимит zram: ~16 GiB при 32 GiB RAM
    priority = 100;            # выше дискового swap с отрицательным приоритетом
  };

  boot.kernel.sysctl = {
    # Заполнять zram раньше дискового fallback: сжатие в RAM дешевле записи на SSD.
    "vm.swappiness" = 180;

    # Раньше начинать прямой реклейм, не ждать нехватки памяти
    "vm.watermark_scale_factor" = 125;
    "vm.watermark_boost_factor" = 0;

    # Для zram: не читать вперёд, страницы сжаты и не на диске
    "vm.page-cluster" = 0;
  };

  # === 2. COREDUMP — не дампить гигантские Electron-процессы ===
  # Большой Electron-coredump может надолго занять диск и заморозить систему.
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
