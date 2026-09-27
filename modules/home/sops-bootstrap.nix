# Bootstrap helper: fetch the sops age private key from Bitwarden.
# The key must exist at ~/.config/sops/age/keys.txt (see modules/core/default.nix:
# sops.age.keyFile) before `nixos-rebuild` can decrypt secrets/*.yaml on a new
# machine. Store the key in Bitwarden as a Secure Note named "sops-age-key"
# (put the private key line, "AGE-SECRET-KEY-...", in the note field).
{
  pkgs,
  ...
}:
{
  home.file.".local/bin/sops-key-fetch" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      dest="$HOME/.config/sops/age/keys.txt"
      if [ -s "$dest" ]; then
        echo "already exists: $dest" >&2
        exit 0
      fi
      if [ "''${BW_SESSION:-}" = "" ]; then
        echo "Run: bw login && export BW_SESSION=\$(bw unlock --raw)" >&2
        exit 1
      fi
      key=$(${pkgs.bitwarden-cli}/bin/bw get notes sops-age-key | \
            ${pkgs.gnugrep}/bin/grep -o 'AGE-SECRET-KEY-[A-Z0-9]*')
      if [ -z "$key" ]; then
        echo "secure note 'sops-age-key' not found or has no AGE-SECRET-KEY" >&2
        exit 1
      fi
      mkdir -p "$(dirname "$dest")"
      umask 077
      printf '%s\n' "$key" > "$dest"
      echo "sops age key installed to $dest"
    '';
  };

  # Source secret env in every zsh — covers SSH sessions where the greetd
  # wrapper in modules/core/niri.nix never runs. kimi-mcp.env is the sops
  # fallback rendered at activation; ~/.cache/kimi-code/env is the live cache
  # refreshed from Infisical by kimi-secrets.timer — sourced last so it wins.
  # set -a is required: dotenv files carry bare KEY=value that would otherwise
  # stay unexported shell params invisible to child processes.
  programs.zsh.envExtra = ''
    set -a
    [ -f /run/secrets/kimi-mcp.env ] && . /run/secrets/kimi-mcp.env
    [ -f "$HOME/.cache/kimi-code/env" ] && . "$HOME/.cache/kimi-code/env"
    set +a
  '';
}
