# Periodically pull kimi-code API keys from Infisical (project nixos-configs,
# machine identity nixos-hosts) into ~/.cache/kimi-code/env. Both zsh
# (modules/home/sops-bootstrap.nix) and the greetd session wrapper
# (modules/core/niri.nix) source that file, so keys edited in the Infisical UI
# reach new processes within a few minutes — no nixos-rebuild needed.
# Bootstrap creds come from sops: /run/secrets/infisical-ua.env
# (modules/core/default.nix). On fetch failure the previous cache stays in
# place, so offline boots keep working.
{
  pkgs,
  configRoot,
  ...
}:
let
  secretspec = pkgs.callPackage ../../pkgs/secretspec.nix { };
  fetchScript = pkgs.writeShellScript "kimi-secrets-fetch" ''
    set -euo pipefail
    mkdir -p "$HOME/.cache/kimi-code"
    dest="$HOME/.cache/kimi-code/env"
    tmp="$(mktemp "$dest.tmp.XXXXXX")"
    trap 'rm -f "$tmp"' EXIT
    if ${secretspec}/bin/secretspec \
        -f "${configRoot}/configs/kimi-secrets/secretspec.toml" \
        export --format dotenv > "$tmp"; then
      # mcp.json reads KIMI_21ST_API_KEY (bearerTokenEnvVar); Infisical stores
      # the value under TWENTYFIRST_API_KEY.
      ${pkgs.gnugrep}/bin/grep '^TWENTYFIRST_API_KEY=' "$tmp" \
        | ${pkgs.gnused}/bin/sed 's/^TWENTYFIRST_API_KEY=/KIMI_21ST_API_KEY=/' >> "$tmp"
      chmod 600 "$tmp"
      mv -f "$tmp" "$dest"
    else
      echo "kimi-secrets: export failed, keeping previous cache" >&2
      rm -f "$tmp"
      exit 1
    fi
  '';
in
{
  systemd.user.services.kimi-secrets = {
    Unit.Description = "Fetch kimi-code API keys from Infisical into a local env cache";
    Service = {
      Type = "oneshot";
      EnvironmentFile = "-/run/secrets/infisical-ua.env";
      ExecStart = fetchScript;
    };
  };

  systemd.user.timers.kimi-secrets = {
    Unit.Description = "Refresh kimi-code API keys from Infisical";
    Timer = {
      OnActiveSec = "10s";
      OnUnitActiveSec = "3min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
