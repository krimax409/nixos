{ pkgs, host, ... }:
let
  browser = "google-chrome-stable";
  terminal = "ghostty";
in
{
  home.packages = with pkgs; [
    nwg-displays
    swww
    grimblast
    hyprpicker
    grim
    slurp
    wl-clip-persist
    cliphist
    wf-recorder
    glib
    wayland
    direnv
  ];

  # Session variables
  home.sessionVariables = {
    NIXOS_OZONE_WL = 1;
    __GL_GSYNC_ALLOWED = 0;
    __GL_VRR_ALLOWED = 0;
    _JAVA_AWT_WM_NONEREPARENTING = 1;
    SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
    DISABLE_QT5_COMPAT = 0;
    GDK_BACKEND = "wayland";
    ANKI_WAYLAND = 1;
    DIRENV_LOG_FORMAT = "";
    WLR_DRM_NO_ATOMIC = 1;
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    MOZ_ENABLE_WAYLAND = 1;
    WLR_BACKEND = "vulkan";
    WLR_RENDERER = "vulkan";
    WLR_NO_HARDWARE_CURSORS = 1;
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    GTK_THEME = "Colloid-Green-Dark-Gruvbox";
    GRIMBLAST_HIDE_CURSOR = 0;
  };

  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  # Hyprlock
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        no_fade_in = false;
        disable_loading_bar = true;
        ignore_empty_input = true;
        fractional_scaling = 0;
      };

      background = [
        {
          monitor = "";
          path = "${../../wallpapers/otherWallpaper/gruvbox/forest_road.jpg}";
          blur_passes = 2;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];

      shape = [
        {
          monitor = "";
          size = "300, 50";
          color = "rgba(102, 92, 84, 0.33)";
          rounding = 10;
          border_color = "rgba(255, 255, 255, 0)";
          position = "0, ${if host == "laptop" then "120" else "270"}";
          halign = "center";
          valign = "bottom";
        }
      ];

      label = [
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +'%k:%M')"'';
          color = "rgba(235, 219, 178, 0.9)";
          font_size = 115;
          font_family = "Maple Mono Bold";
          shadow_passes = 3;
          position = "0, ${if host == "laptop" then "-25" else "-150"}";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = ''cmd[update:1000] echo "- $(date +'%A, %B %d') -" '';
          color = "rgba(235, 219, 178, 0.9)";
          font_size = 18;
          font_family = "Maple Mono";
          shadow_passes = 3;
          position = "0, ${if host == "laptop" then "-225" else "-350"}";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = "  $USER";
          color = "rgba(235, 219, 178, 1)";
          font_size = 15;
          font_family = "Maple Mono Bold";
          position = "0, ${if host == "laptop" then "131" else "281"}";
          halign = "center";
          valign = "bottom";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 1;
          rounding = 10;
          dots_size = 0.25;
          dots_spacing = 0.4;
          dots_center = true;
          outer_color = "rgba(102, 92, 84, 0.33)";
          inner_color = "rgba(102, 92, 84, 0.33)";
          color = "rgba(235, 219, 178, 0.9)";
          font_color = "rgba(235, 219, 178, 0.9)";
          font_size = 14;
          font_family = "Maple Mono Bold";
          fade_on_empty = false;
          placeholder_text = ''<i><span foreground="##fbf1c7">Enter Password</span></i>'';
          hide_input = false;
          position = "0, ${if host == "laptop" then "50" else "200"}";
          halign = "center";
          valign = "bottom";
        }
      ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    xwayland.enable = true;
    systemd.enable = true;

    settings = {
      "$mainMod" = "SUPER";

      exec-once = [
        "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "nm-applet &"
        "throne &"
        "wl-clip-persist --clipboard both &"
        "wl-paste --watch cliphist store &"
        "waybar &"
        "swaync &"
        "hyprctl setcursor Posy_Cursor 24 &"
        "swww-daemon &"
        "${terminal} --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false"
        "[workspace 1 silent] ${browser}"
        "[workspace 2 silent] ${terminal}"
        "[workspace 9 silent] steam"
        "[workspace 10 silent] discord"
      ];

      input = {
        kb_layout = "us,ru";
        kb_options = "grp:alt_space_toggle";
        numlock_by_default = true;
        repeat_delay = 300;
        follow_mouse = 0;
        float_switch_override_focus = 0;
        mouse_refocus = 0;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
        };
      };

      cursor = {
        no_hardware_cursors = true;
      };

      general = {
        layout = "dwindle";
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = "rgb(98971A) rgb(CC241D) 45deg";
        "col.inactive_border" = "0x00000000";
        snap = {
          enabled = true;
          window_gap = 10;
          monitor_gap = 10;
        };
      };

      misc = {
        disable_autoreload = true;
        disable_hyprland_logo = true;
        enable_swallow = true;
        focus_on_activate = true;
        middle_click_paste = false;
      };

      dwindle = {
        force_split = 2;
        special_scale_factor = 1.0;
        split_width_multiplier = 1.0;
        use_active_for_splits = true;
        pseudotile = "yes";
        preserve_split = "yes";
      };

      master = {
        new_status = "master";
        special_scale_factor = 1;
      };

      decoration = {
        rounding = 0;
        blur = {
          enabled = true;
          size = 3;
          passes = 2;
          brightness = 1;
          contrast = 1.4;
          ignore_opacity = true;
          noise = 0;
          new_optimizations = true;
          xray = true;
        };
        shadow = {
          enabled = true;
          ignore_window = true;
          offset = "0 2";
          range = 20;
          render_power = 3;
          color = "rgba(00000055)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "fluent_decel, 0, 0.2, 0.4, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
          "fade_curve, 0, 0.55, 0.45, 1"
        ];
        animation = [
          "windowsIn,   0, 4, easeOutCubic,  popin 20%"
          "windowsOut,  0, 4, fluent_decel,  popin 80%"
          "windowsMove, 1, 2, fluent_decel, slide"
          "fadeIn,      1, 3,   fade_curve"
          "fadeOut,     1, 3,   fade_curve"
          "fadeSwitch,  0, 1,   easeOutCirc"
          "fadeShadow,  1, 10,  easeOutCirc"
          "fadeDim,     1, 4,   fluent_decel"
          "workspaces,  1, 4,   easeOutCubic, slide"
        ];
      };

      binds = {
        movefocus_cycles_fullscreen = true;
      };

      bind = [
        "$mainMod, F1, exec, show-keybinds"
        "$mainMod, Return, exec, ${terminal} --gtk-single-instance=true"
        "ALT, Return, exec, [float; size 1111 700] ${terminal}"
        "$mainMod SHIFT, Return, exec, [fullscreen] ${terminal}"
        "$mainMod, B, exec, [workspace 1 silent] ${browser}"
        "$mainMod, Q, killactive,"
        "$mainMod, F, fullscreen, 0"
        "$mainMod SHIFT, F, fullscreen, 1"
        "$mainMod, Space, exec, toggle-float"
        "$mainMod, D, exec, rofi -show drun || pkill rofi"
        "$mainMod SHIFT, D, exec, webcord --enable-features=UseOzonePlatform --ozone-platform=wayland"
        "$mainMod SHIFT, S, exec, hyprctl dispatch exec '[workspace 5 silent] SoundWireServer'"
        "$mainMod, Escape, exec, swaylock"
        "ALT, Escape, exec, hyprlock"
        "$mainMod SHIFT, Escape, exec, power-menu"
        "$mainMod, P, pseudo,"
        "$mainMod, X, togglesplit,"
        "$mainMod, Y, workspaceopt, allfloat"

        # alt-tab window cycling (preserves fullscreen)
        "ALT, Tab, exec, alt-tab"
        "ALT SHIFT, Tab, exec, alt-tab prev"
        "$mainMod, T, exec, toggle-oppacity"
        "$mainMod, E, exec, nemo"
        "ALT, E, exec, hyprctl dispatch exec '[float; size 1111 700] nemo'"
        "$mainMod SHIFT, B, exec, toggle-waybar"
        "$mainMod, C ,exec, hyprpicker -a"
        "$mainMod, W,exec, wallpaper-picker"
        "$mainMod SHIFT, W,exec, hyprctl dispatch exec '[float; size 925 615] waypaper'"
        "$mainMod, N, exec, swaync-client -t -sw"
        "CTRL SHIFT, Escape, exec, hyprctl dispatch exec '[workspace 9] missioncenter'"
        "$mainMod, equal, exec, woomer"

        # screenshot
        ",Print, exec, screenshot --copy"
        "$mainMod, Print, exec, screenshot --save"
        "$mainMod SHIFT, Print, exec, screenshot --swappy"

        # switch focus
        "$mainMod, left,  movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up,    movefocus, u"
        "$mainMod, down,  movefocus, d"
        "$mainMod, h, movefocus, l"
        "$mainMod, j, movefocus, d"
        "$mainMod, k, movefocus, u"
        "$mainMod, l, movefocus, r"

        "$mainMod, left,  alterzorder, top"
        "$mainMod, right, alterzorder, top"
        "$mainMod, up,    alterzorder, top"
        "$mainMod, down,  alterzorder, top"
        "$mainMod, h, alterzorder, top"
        "$mainMod, j, alterzorder, top"
        "$mainMod, k, alterzorder, top"
        "$mainMod, l, alterzorder, top"

        "CTRL ALT, up, exec, hyprctl dispatch focuswindow floating"
        "CTRL ALT, down, exec, hyprctl dispatch focuswindow tiled"

        # switch workspace
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
        "$mainMod SHIFT, 0, movetoworkspacesilent, 10"
        "$mainMod CTRL, c, movetoworkspace, empty"

        # window control
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"
        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, j, movewindow, d"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, l, movewindow, r"

        "$mainMod CTRL, left, resizeactive, -80 0"
        "$mainMod CTRL, right, resizeactive, 80 0"
        "$mainMod CTRL, up, resizeactive, 0 -80"
        "$mainMod CTRL, down, resizeactive, 0 80"
        "$mainMod CTRL, h, resizeactive, -80 0"
        "$mainMod CTRL, j, resizeactive, 0 80"
        "$mainMod CTRL, k, resizeactive, 0 -80"
        "$mainMod CTRL, l, resizeactive, 80 0"

        "$mainMod ALT, left, moveactive,  -80 0"
        "$mainMod ALT, right, moveactive, 80 0"
        "$mainMod ALT, up, moveactive, 0 -80"
        "$mainMod ALT, down, moveactive, 0 80"
        "$mainMod ALT, h, moveactive,  -80 0"
        "$mainMod ALT, j, moveactive, 0 80"
        "$mainMod ALT, k, moveactive, 0 -80"
        "$mainMod ALT, l, moveactive, 80 0"

        # media
        ",XF86AudioPlay,exec, playerctl play-pause"
        ",XF86AudioNext,exec, playerctl next"
        ",XF86AudioPrev,exec, playerctl previous"
        ",XF86AudioStop,exec, playerctl stop"

        "$mainMod, mouse_down, exec, workspace-scroll -1"
        "$mainMod, mouse_up, exec, workspace-scroll +1"

        # clipboard
        ''$mainMod, V, exec, cliphist list | rofi -dmenu -theme-str 'window {width: 50%;} listview {columns: 1;}' | cliphist decode | wl-copy''
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      windowrule = [
        # Float rules
        "match:class Viewnior, float on"
        "match:class imv, float on"
        "match:class mpv, float on"
        "match:class Aseprite, float off"
        "match:class Audacious, float on"
        "match:class rofi, pin on"
        "match:class waypaper, pin on, float on"
        "match:class nwg-displays, float on"
        "match:title Transmission, float on"
        "match:title Volume Control, float on, size 700 450, move 40 55%"
        "match:title Firefox — Sharing Indicator, float on, move 0 0"
        "match:title Picture-in-Picture, float on, pin on, opacity 1.0 override 1.0 override"

        # Opacity overrides
        "match:title .*imv.*, opacity 1.0 override 1.0 override"
        "match:title .*mpv.*, opacity 1.0 override 1.0 override"
        "match:class Aseprite, opacity 1.0 override 1.0 override"
        "match:class Unity, opacity 1.0 override 1.0 override"
        "match:class zen, opacity 1.0 override 1.0 override"
        "match:class evince, opacity 1.0 override 1.0 override"

        # Workspace assignments
        "match:class google-chrome, workspace 1"
        "match:class evince, workspace 3"
        "match:class Gimp-2.10, workspace 4"
        "match:class Aseprite, workspace 4"
        "match:class Audacious, workspace 5"
        "match:class Spotify, workspace 5"
        "match:class com.obsproject.Studio, workspace 8"
        "match:class discord, workspace 10"
        "match:class WebCord, workspace 10"

        # Bitwarden - floating, pinned on top, no taskbar
        "match:class Bitwarden, float on, pin on, size 400 600"

        # Float for various apps
        "match:class org.gnome.Calculator, float on"
        "match:class zenity, float on, size 850 500"
        "match:class SoundWireServer, float on, size 725 330"
        "match:class org.gnome.FileRoller, float on"
        "match:class org.pulseaudio.pavucontrol, float on"
        "match:class .sameboy-wrapped, float on"
        "match:class file_progress, float on"
        "match:class confirm, float on"
        "match:class dialog, float on"
        "match:class download, float on"
        "match:class notification, float on"
        "match:class error, float on"
        "match:class confirmreset, float on"
        "match:title Open File, float on"
        "match:title File Upload, float on"
        "match:title branchdialog, float on"
        "match:title Confirm to replace files, float on"
        "match:title File Operation Progress, float on"

        # xwaylandvideobridge
        "match:class xwaylandvideobridge, opacity 0.0 override, no_anim on, no_initial_focus on, max_size 1 1, no_blur on"

      ];

      workspace = [
        "w[t1], gapsout:0, gapsin:0"
        "w[tg1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"
        "9, monitor:DP-1"
      ];
    };

    extraConfig = "
      # Fallback for monitors not configured via nwg-displays
      monitor=,preferred,auto,1

      # Monitor layout managed by nwg-displays
      source = ~/.config/hypr/monitors.conf

      xwayland {
        force_zero_scaling = true
      }
    ";
  };
}
