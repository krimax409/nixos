{
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
    [ -f "$HOME/.cache/kimi-code/env" ] && . "$HOME/.cache/kimi-code/env" || true
    set +a
    exec ${pkgs.niri}/bin/niri-session
  '';
in
{
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
          command = "${niriSession}";
          user = username;
        };
        default_session.command = lib.concatStringsSep " " [
          (lib.getExe pkgs.tuigreet)
          "--time"
          "--remember"
          "--remember-session"
          "--asterisks"
          "--cmd"
          "${niriSession}"
        ];
      };
    };

    udisks2.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      brightnessctl
      xwayland-satellite
    ];
    sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
    };
  };

  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
