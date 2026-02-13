{ inputs, pkgs, ... }:
{
  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  programs.plasma = {
    enable = true;

    # Горячие клавиши
    hotkeys.commands."launch-kitty" = {
      name = "Launch Kitty";
      key = "Meta+Return";
      command = "kitty";
    };

    # Настройки внешнего вида
    workspace = {
      # Темная тема
      lookAndFeel = "org.kde.breezedark.desktop";
      colorScheme = "BreezeDark";

      # Курсор
      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };

      # Обои
      # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images/1920x1080.png";
    };

    # Настройки окон
    kwin = {
      # Эффекты
      effects = {
        desktopSwitching.animation = "slide";
        translucency.enable = true;
      };

      # Поведение окон
      titlebarButtons = {
        left = [
          "close"
          "minimize"
          "maximize"
        ];
        right = [ "help" ];
      };
    };

    # Панель задач внизу с автоскрытием
    panels = [
      {
        location = "bottom";
        height = 44;
        hiding = "dodgewindows"; # Всегда скрывается когда есть окна, показывается при наведении
        floating = false;

        widgets = [
          # Меню приложений
          {
            name = "org.kde.plasma.kickoff";
            config = {
              General = {
                icon = "start-here-kde";
                favorites = [
                  "preferred://browser"
                  "org.kde.dolphin.desktop"
                  "kitty.desktop"
                  "org.kde.kate.desktop"
                ];
              };
            };
          }

          # Переключатель задач (открытые приложения)
          {
            name = "org.kde.plasma.icontasks";
            config = {
              General = {
                launchers = [
                  "preferred://browser"
                  "preferred://filemanager"
                  "kitty.desktop"
                ];
                showOnlyCurrentDesktop = false;
                groupingStrategy = 0; # Не группировать окна
              };
            };
          }

          # Разделитель (пружинка)
          "org.kde.plasma.panelspacer"

          # Системный трей
          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.volume"
                "org.kde.plasma.bluetooth"
              ];
              hidden = [ "org.kde.plasma.clipboard" ];
            };
          }

          # Часы и календарь
          {
            digitalClock = {
              calendar.firstDayOfWeek = "monday";
              time.format = "24h";
            };
          }
        ];
      }
    ];

    # Настройки файлового менеджера Dolphin
    configFile = {
      "kdeglobals"."KDE"."SingleClick" = false; # Двойной клик для открытия

      "kwinrc"."Windows"."Placement" = "Smart"; # Умное размещение окон

      "kwinrc"."Desktops" = {
        Number = 4;
        Rows = 1;
      };
    };
  };
}
