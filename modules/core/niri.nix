{
  config,
  configRoot,
  host,
  lib,
  pkgs,
  username,
  ...
}:
let
  # greetd prepends `exec` to session commands (`sh -c "exec <command>"`), so the
  # value must be a single executable path — inline shell like `set -a; ...`
  # makes greetd run `exec set` and the session dies instantly. A store script
  # is also safe from sops secrets being unreadable: bash-as-sh aborts the whole
  # script if `.` fails, so each source line ends with `|| true`.
  niriSession = pkgs.writeShellScript "niri-session-env" ''
    set -a
    [ -f /run/secrets/kimi-mcp.env ] && . /run/secrets/kimi-mcp.env || true
    [ -f "$HOME/.config/kimi-code/secrets.env" ] && . "$HOME/.config/kimi-code/secrets.env" || true
    set +a
    exec ${pkgs.niri}/bin/niri-session
  '';

  laptop = host == "laptop";
  hyprlandConfig = "${configRoot}/configs/hyprland";
  hyprland = config.programs.hyprland.package;
  uwsm = config.programs.uwsm.package;
  hyprlandRuntime = with pkgs; [
    hyprland
    uwsm
    grim
    slurp
    wl-clipboard
    libnotify
    jq
  ];
  sessionEnv = ''
    export PATH="${lib.makeBinPath hyprlandRuntime}:$HOME/.local/bin:/etc/profiles/per-user/${username}/bin:$PATH"
    export HYPRLAND_LAPTOP_CONFIG=${lib.escapeShellArg hyprlandConfig}
  '';
  hyprlandCompositor = pkgs.writeShellScript "hyprland-laptop-compositor" ''
    ${sessionEnv}
    export HYPRLAND_LAPTOP_UWSM=1
    export UWSM_FINALIZE_VARNAMES="HYPRLAND_INSTANCE_SIGNATURE HYPRLAND_CMD XCURSOR_THEME XCURSOR_SIZE"
    exec ${hyprland}/bin/start-hyprland -- -c "$HYPRLAND_LAPTOP_CONFIG/hyprland.lua"
  '';
  hyprlandSession = pkgs.writeShellScriptBin "hyprland-laptop" ''
    set -eu
    ${sessionEnv}
    if [ "''${1:-}" = --check ]; then
      noctalia config validate "$HYPRLAND_LAPTOP_CONFIG/noctalia"
      exec ${hyprland}/bin/Hyprland --verify-config -c "$HYPRLAND_LAPTOP_CONFIG/hyprland.lua"
    fi
    exec ${lib.getExe uwsm} start -e -D Hyprland -N Hyprland -- ${hyprlandCompositor}
  '';
  laptopSessions = pkgs.linkFarm "laptop-wayland-sessions" [
    {
      name = "hyprland.desktop";
      path = pkgs.writeText "laptop-hyprland.desktop" ''
        [Desktop Entry]
        Name=Hyprland
        Comment=Scrolling Wayland desktop
        Exec=${lib.getExe hyprlandSession}
        Type=Application
        DesktopNames=Hyprland
      '';
    }
    {
      name = "niri.desktop";
      path = pkgs.writeText "laptop-niri.desktop" ''
        [Desktop Entry]
        Name=Niri (fallback)
        Comment=Previous Wayland desktop
        Exec=${niriSession}
        Type=Application
        DesktopNames=niri
      '';
    }
  ];
  defaultSession = if laptop then lib.getExe hyprlandSession else toString niriSession;
in
{
  programs.hyprland = lib.mkIf laptop {
    enable = true;
    withUWSM = true;
  };
  system.build.hyprlandLaptopSession = lib.mkIf laptop hyprlandSession;

  programs.niri = {
    enable = true;
    useNautilus = false;
  };

  services = {
    greetd = {
      enable = true;
      useTextGreeter = true;
      settings = {
        initial_session = {
          command = defaultSession;
          user = username;
        };
        default_session.command = lib.concatStringsSep " " (
          [
            (lib.getExe pkgs.tuigreet)
            "--time"
            "--remember"
            "--remember-session"
            "--asterisks"
            "--cmd"
            defaultSession
          ]
          ++ lib.optionals laptop [
            "--sessions"
            "${laptopSessions}"
          ]
        );
      };
    };

    displayManager.defaultSession = lib.mkIf laptop "hyprland";
    udisks2.enable = true;
  };

  environment = {
    systemPackages = [
      pkgs.brightnessctl
      pkgs.xwayland-satellite
    ]
    ++ lib.optional laptop hyprlandSession;
    sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
    };
  };

  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
