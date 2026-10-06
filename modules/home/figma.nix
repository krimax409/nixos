# Figma: unofficial Electron desktop client (figma-linux) plus figma-agent,
# the local font helper figma.com queries on 127.0.0.1:44950. Units mirror
# upstream files/figma-agent.{service,socket} (socket activation).
# In a regular browser figma.com only talks to the agent with a Windows
# user agent override (see upstream README).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # All traffic goes through the Throne proxy so the account always sees the
  # same non-RU exit; WebRTC must not send UDP around it. Loopback (the agent)
  # bypasses the proxy by default.
  figmaLinux = pkgs.symlinkJoin {
    name = "figma-linux-proxied";
    paths = [ pkgs.figma-linux ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/figma-linux \
        --add-flags "--proxy-server=http://127.0.0.1:2080" \
        --add-flags "--force-webrtc-ip-handling-policy=disable_non_proxied_udp"
    '';
  };
in
{
  home.packages = [ figmaLinux ];

  # figma-linux's own themes repaint Figma with a light palette and override
  # Figma's dark theme. settings.json also holds mutable app state, so only
  # this key is enforced; the app merges a partial file with its defaults.
  home.activation.figmaLinuxDisableThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="${config.xdg.configHome}/figma-linux/settings.json"
    if [ -f "$settings" ]; then
      ${pkgs.jq}/bin/jq '.app.disableThemes = true' "$settings" > "$settings.tmp"
      mv -f "$settings.tmp" "$settings"
    else
      mkdir -p "$(dirname "$settings")"
      echo '{"app":{"disableThemes":true}}' > "$settings"
    fi
  '';

  # Upstream entry lacks MimeType, so the figma:// login callback from the
  # browser finds no handler (mimeapps.list is read-only, Electron can't
  # register itself).
  xdg.desktopEntries.figma-linux = {
    name = "Figma Linux";
    comment = "Unofficial Figma desktop application for Linux";
    exec = "${figmaLinux}/bin/figma-linux %U";
    icon = "figma-linux";
    terminal = false;
    mimeType = [ "x-scheme-handler/figma" ];
  };

  systemd.user.sockets.figma-agent = {
    Unit.Description = "Figma Agent for Linux Socket";
    Socket.ListenStream = "127.0.0.1:44950";
    Install.WantedBy = [ "sockets.target" ];
  };

  systemd.user.services.figma-agent = {
    Unit = {
      Description = "Figma Agent for Linux Service";
      Requires = [ "figma-agent.socket" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${pkgs.figma-agent}/bin/figma-agent";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
