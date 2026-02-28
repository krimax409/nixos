import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "plasma";
  description = "KDE Plasma 6 declarative desktop";
  category = "desktop";
  deps = [ "gtk" ];

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      programs.plasma = {
        enable = true;

        workspace = {
          lookAndFeel = "org.kde.breezedark.desktop";
          colorScheme = "BreezeDark";
          cursor = {
            theme = "Posy_Cursor";
            size = 24;
          };
          iconTheme = "Adwaita";
          clickItemTo = "select";
          tooltipDelay = 5;
        };

        fonts = {
          general = {
            family = "Noto Sans";
            pointSize = 11;
          };
          fixedWidth = {
            family = "Maple Mono NF";
            pointSize = 11;
          };
          small = {
            family = "Noto Sans";
            pointSize = 9;
          };
          toolbar = {
            family = "Noto Sans";
            pointSize = 10;
          };
          menu = {
            family = "Noto Sans";
            pointSize = 10;
          };
          windowTitle = {
            family = "Noto Sans";
            pointSize = 10;
          };
        };

        panels = [
          {
            location = "bottom";
            height = 44;
            floating = true;
            widgets = [
              {
                kickoff = {
                  icon = "nix-snowflake-white";
                  sortAlphabetically = true;
                };
              }
              {
                iconTasks = {
                  launchers = [
                    "applications:org.kde.dolphin.desktop"
                    "applications:org.kde.konsole.desktop"
                  ];
                };
              }
              "org.kde.plasma.marginsseparator"
              {
                systemTray.items = {
                  shown = [
                    "org.kde.plasma.networkmanagement"
                    "org.kde.plasma.volume"
                    "org.kde.plasma.bluetooth"
                  ];
                };
              }
              {
                digitalClock = {
                  calendar.firstDayOfWeek = "monday";
                  time.format = "24h";
                };
              }
            ];
          }
        ];

        kwin = {
          titlebarButtons = {
            left = [ "on-all-desktops" ];
            right = [
              "minimize"
              "maximize"
              "close"
            ];
          };
          effects = {
            blur.enable = true;
            desktopSwitching.animation = "slide";
            minimization.animation = "magiclamp";
          };
        };

        shortcuts = {
          kwin = {
            "Switch to Desktop 1" = "Meta+1";
            "Switch to Desktop 2" = "Meta+2";
            "Switch to Desktop 3" = "Meta+3";
            "Switch to Desktop 4" = "Meta+4";
            "Window to Desktop 1" = "Meta+!";
            "Window to Desktop 2" = "Meta+@";
            "Window to Desktop 3" = "Meta+#";
            "Window to Desktop 4" = "Meta+$";
            "Window Close" = "Meta+Q";
            "Window Maximize" = "Meta+F";
            "Window Minimize" = "Meta+M";
            "Window Fullscreen" = "Meta+Shift+F";
          };
          ksmserver = {
            "Lock Session" = "Meta+Escape";
          };
        };

        hotkeys.commands = {
          "launch-terminal" = {
            name = "Launch Terminal";
            key = "Meta+Return";
            command = "kitty";
          };
          "launch-browser" = {
            name = "Launch Browser";
            key = "Meta+B";
            command = "firefox";
          };
          "launch-file-manager" = {
            name = "Launch File Manager";
            key = "Meta+E";
            command = "dolphin";
          };
        };

        input.keyboard = {
          layouts = [
            { layout = "us"; }
            { layout = "ru"; }
          ];
          options = [ "grp:alt_shift_toggle" ];
        };
      };
    };
}
