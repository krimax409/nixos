{
  programs.zsh = {
    shellAliases = {
      # Utils
      c = "clear";
      cd = "z";
      tt = "gtrash put";
      cat = "bat";
      nano = "micro";
      claude = "NO_PROXY=localhost,127.0.0.1,::1 HTTPS_PROXY=http://127.0.0.1:2080 HTTP_PROXY=http://127.0.0.1:2080 ALL_PROXY=http://127.0.0.1:2080 command claude";
      codex = "NO_PROXY=localhost,127.0.0.1,::1 HTTPS_PROXY=http://127.0.0.1:2080 HTTP_PROXY=http://127.0.0.1:2080 ALL_PROXY=http://127.0.0.1:2080 command codex";
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
      nft = "nh os test";
      nfs = "nh os switch";
      nfu = "nh os switch --update";
      # nix-search = "nh search";

      # python
      piv = "python -m venv .venv";
      psv = "source .venv/bin/activate";

    };
  };
}
