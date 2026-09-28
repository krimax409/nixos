{
  config,
  configRoot,
  host,
  inputs,
  pkgs,
  ...
}:
let
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.noctalia = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../../patches/noctalia-taskbar-indicator-offset.patch ];
    });
  };

  xdg.configFile = {
    "niri/config.kdl" = {
      source = outOfStore "${configRoot}/configs/niri/${host}.kdl";
      force = true;
    };
    "niri/common.kdl" = {
      source = outOfStore "${configRoot}/configs/niri/common.kdl";
      force = true;
    };
    "noctalia/config.toml" = {
      source = outOfStore "${configRoot}/configs/noctalia/config.toml";
      force = true;
    };
    "noctalia/palettes/windows-dark.json" = {
      source = outOfStore "${configRoot}/configs/noctalia/palettes/windows-dark.json";
      force = true;
    };
  };

  xdg.stateFile."noctalia/settings.toml" = {
    source = outOfStore "${configRoot}/configs/noctalia/${host}/settings.toml";
    force = true;
  };

  # Float windows of XWayland apps whose app_id arrives too late for niri's
  # open-rules.
  #
  # niri evaluates `open-floating` once, inside send_initial_configure. For
  # XWayland windows (Steam et al.) xwayland-satellite sets app_id/title after
  # the surface already mapped, so app-id/title matches silently never fire.
  # Verified live on niri 26.04 + xwayland-satellite 0.8.2: even a bare
  # `match app-id="steam"` does not float a new Steam window, while
  # `niri msg action move-window-to-floating` works immediately.
  #
  # This daemon listens to the niri event stream and floats every window whose
  # app_id lands in the list below, compensating for the missed open-rule.
  # Spawned by niri at session start (see configs/niri/common.kdl).
  home.file.".local/bin/niri-float-apps" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # Space-separated app_ids to force-float.
      FLOAT_APP_IDS="''${NIRI_FLOAT_APP_IDS:-steam}"

      declare -A seen=()

      is_target() {
          [[ " $FLOAT_APP_IDS " == *" $1 "* ]]
      }

      float_new_windows() {
          niri msg --json event-stream | ${pkgs.jq}/bin/jq -rc --unbuffered '
              ((.WindowsChanged.windows // [])[], (.WindowOpenedOrChanged.window // empty))
              | select(.app_id != null and .is_floating == false)
              | "\(.id)\t\(.app_id)"
          ' | while IFS=$'\t' read -r id app_id; do
              if is_target "$app_id" && [[ -z ''${seen[$id]:-} ]]; then
                  seen[$id]=1
                  niri msg action move-window-to-floating --id "$id" 2>/dev/null || true
              fi
          done
      }

      # Reconnect if the stream drops (e.g. niri restart); niri msg exits on EOF.
      while true; do
          float_new_windows || true
          sleep 2
      done
    '';
  };
}
