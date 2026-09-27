# Periodically pull kimi-code API keys from Infisical (project nixos-configs,
# machine identity nixos-hosts) into ~/.cache/kimi-code/env. Both zsh
# (modules/home/sops-bootstrap.nix) and the greetd session wrapper
# (modules/core/niri.nix) source that file, so keys edited in the Infisical UI
# reach new processes within a few minutes — no nixos-rebuild needed.
# Bootstrap creds come from sops: /run/secrets/infisical-ua.env
# (modules/core/default.nix). On fetch failure the previous cache stays in
# place, so offline boots keep working.
#
# NOTE: the cache is written in `secretspec export --format shell` form
# (`export KEY='value'`), i.e. real shell syntax — values with spaces or
# metacharacters stay safe when sourced. The manifest path is a store path
# (immutable per generation): editing configs/kimi-secrets/secretspec.toml
# requires a rebuild, which is the point of a declarative backend list.
{
  pkgs,
  ...
}:
let
  secretspec = pkgs.callPackage ../../pkgs/secretspec.nix { };
  coreutils = pkgs.coreutils;
  manifest = ../../configs/kimi-secrets/secretspec.toml;
  fetchScript = pkgs.writeShellScript "kimi-secrets-fetch" ''
    set -euo pipefail
    ${coreutils}/bin/mkdir -p "$HOME/.cache/kimi-code"
    dest="$HOME/.cache/kimi-code/env"
    tmp="$(${coreutils}/bin/mktemp "$dest.tmp.XXXXXX")"
    trap '${coreutils}/bin/rm -f "$tmp"' EXIT
    if ${secretspec}/bin/secretspec -f "${manifest}" export --format shell > "$tmp"; then
      # mcp.json reads KIMI_21ST_API_KEY (bearerTokenEnvVar); Infisical stores
      # the value under TWENTYFIRST_API_KEY.
      ${pkgs.gnugrep}/bin/grep '^export TWENTYFIRST_API_KEY=' "$tmp" \
        | ${pkgs.gnused}/bin/sed 's/^export TWENTYFIRST_API_KEY=/export KIMI_21ST_API_KEY=/' >> "$tmp"
      ${coreutils}/bin/chmod 600 "$tmp"
      ${coreutils}/bin/mv -f "$tmp" "$dest"
    else
      echo "kimi-secrets: export failed, keeping previous cache" >&2
      ${coreutils}/bin/rm -f "$tmp"
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
