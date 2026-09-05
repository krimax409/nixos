{ host, ... }:
let
  # Прокси Throne для CLI-агентов. В обход, помимо loopback, идёт
  # 100.64.0.0/10 — CGNAT-диапазон Tailscale: peers тайлнета доступны только
  # напрямую через tailscale0, а прокси на них отвечает 502. Без этого
  # запущенный из терминала `hermes desktop` не получал WebSocket-тикет
  # у gateway на hermes-vm и висел на экране загрузки.
  noProxy = "localhost,127.0.0.1,::1,100.64.0.0/10,.ts.net";
  proxyUrl = "http://127.0.0.1:2080";
  proxyEnv = "NO_PROXY=${noProxy} no_proxy=${noProxy} HTTPS_PROXY=${proxyUrl} HTTP_PROXY=${proxyUrl} ALL_PROXY=${proxyUrl}";
in
{
  programs.zsh = {
    shellAliases = {
      # Utils
      c = "clear";
      cd = "z";
      tt = "gtrash put";
      cat = "bat";
      nano = "micro";
      claude = "${proxyEnv} command claude";
      codex = "${proxyEnv} command codex";
      # Patched 1.0.3 remains the A6API default; official 1.0.8 is explicit.
      # Provider config lives in tracked TOML linked by modules/home/grok.nix.
      grok = "A6API_GROK_AUTHORIZATION=\"Bearer $($HOME/.local/bin/grok-a6api-token)\" MODELHUB_GROK_AUTHORIZATION=\"Bearer $($HOME/.config/grok-secrets/modelhub-token)\" OPENROUTER_GROK_AUTHORIZATION=\"Bearer $($HOME/.config/grok-secrets/openrouter-token)\" ${proxyEnv} command grok-main-previous";
      agent = "A6API_GROK_AUTHORIZATION=\"Bearer $($HOME/.local/bin/grok-a6api-token)\" MODELHUB_GROK_AUTHORIZATION=\"Bearer $($HOME/.config/grok-secrets/modelhub-token)\" OPENROUTER_GROK_AUTHORIZATION=\"Bearer $($HOME/.config/grok-secrets/openrouter-token)\" ${proxyEnv} command agent-main-previous";
      grok-stable = "A6API_GROK_AUTHORIZATION=\"Bearer $($HOME/.local/bin/grok-a6api-token)\" MODELHUB_GROK_AUTHORIZATION=\"Bearer $($HOME/.config/grok-secrets/modelhub-token)\" OPENROUTER_GROK_AUTHORIZATION=\"Bearer $($HOME/.config/grok-secrets/openrouter-token)\" ${proxyEnv} command grok-stable";
      grok-stable-previous-1-0-5 = "A6API_GROK_AUTHORIZATION=\"Bearer $($HOME/.local/bin/grok-a6api-token)\" ${proxyEnv} command grok-stable-previous-1-0-5";
      grok-stable-previous = "A6API_GROK_AUTHORIZATION=\"Bearer $($HOME/.local/bin/grok-a6api-token)\" ${proxyEnv} command grok-stable-previous";
      diff = "delta --diff-so-fancy --side-by-side";
      pipes = "pipes.sh";
      less = "bat";
      f = "superfile";
      py = "python";
      ipy = "ipython";
      icat = "kitten icat";
      dsize = "du -hs";
      pdf = "tdf";
      open = "xdg-open";
      space = "ncdu";
      man = "BAT_THEME='default' batman";

      l = "eza --icons  -a --group-directories-first -1"; # EZA_ICON_SPACING=2
      ll = "eza --icons  -a --group-directories-first -1 --no-user --long";
      tree = "eza --icons --tree --group-directories-first";

      # Nixos
      cdnix = "cd /etc/nixos/nixos-config && zeditor /etc/nixos/nixos-config";
      ns = "nom-shell --run zsh";
      nd = "nom develop --command zsh";
      nb = "nom build";
      nc = "nh clean all --keep 5";
      # nh wraps internal sudo calls in `env`, incompatible with NOPASSWD allowlist.
      # nixos-rebuild is in the allowlist → passwordless.
      # nfu uses nh intentionally: flake update is infrequent, tty password is fine.
      nft = "sudo nixos-rebuild test --flake /etc/nixos/nixos-config#${host}";
      nfs = "sudo nixos-rebuild switch --flake /etc/nixos/nixos-config#${host}";
      nfu = "nh os switch --update";
      # nix-search = "nh search";

      # python
      piv = "python -m venv .venv";
      psv = "source .venv/bin/activate";

    };
  };
}
