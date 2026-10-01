# Penpot local MCP server (npx @penpot/mcp@stable, global npm install into
# ~/.npm-global). Serves the plugin web server on :4400 and the MCP HTTP
# endpoint on :4401 — both bound to localhost; the WebSocket port 4402 is
# loopback-reachable by the Penpot plugin (browser). To connect: open a
# design file at design.penpot.app, then Plugins (Ctrl+Alt+P) → install
# http://localhost:4400/manifest.json → Open the plugin modal →
# "Connect MCP Server". The plugin lives in the modal inside the Penpot
# tab (an OOPIF iframe) — keep that modal/tab open while working.
# Kimi Code reads the server through ~/.kimi-code/mcp.json (url entry).
#
# Keep this running; the plugin in the browser connects to it. First start
# takes ~1 min while pnpm bootstraps the workspace — the package patches
# its own pnpm-workspace.yaml (allowBuilds esbuild/sharp), so if an upgrade
# re-breaks it, re-apply that file under ~/.npm-global/lib/node_modules/@penpot/mcp.
{ config, ... }:
{
  systemd.user.services.penpot-mcp = {
    Unit = {
      Description = "Penpot local MCP server + plugin web server";
      After = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${config.home.homeDirectory}/.npm-global/bin/penpot-mcp";
      Restart = "on-failure";
      RestartSec = "10s";
      # npx/pnpm bootstrap is slow on first run; don't kill it early.
      TimeoutStartSec = "5min";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
