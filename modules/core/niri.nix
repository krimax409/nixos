{
  lib,
  pkgs,
  username,
  ...
}:
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
          # Must stay a single line: greetd's TOML parser rejects multiline
          # """ strings ("expected equals sign on line, but found none").
          command = "set -a; [ -f /run/secrets/kimi-mcp.env ] && . /run/secrets/kimi-mcp.env; [ -f \"$HOME/.cache/kimi-code/env\" ] && . \"$HOME/.cache/kimi-code/env\"; set +a; exec ${pkgs.niri}/bin/niri-session";
          user = username;
        };
        default_session.command = lib.concatStringsSep " " [
          (lib.getExe pkgs.tuigreet)
          "--time"
          "--remember"
          "--remember-session"
          "--asterisks"
          "--cmd"
          ''"set -a; [ -f /run/secrets/kimi-mcp.env ] && . /run/secrets/kimi-mcp.env; [ -f \"$HOME/.cache/kimi-code/env\" ] && . \"$HOME/.cache/kimi-code/env\"; set +a; exec ${pkgs.niri}/bin/niri-session"''
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
