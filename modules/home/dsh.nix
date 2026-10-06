# DeepSeek Harness (dsh). Nix ships only the wrappers; the npm package lives
# in ~/.local/share/dsh and is updated by hand with `dsh-update` (no rollback).
# There is no Linux desktop build upstream, so "DeepSeek Harness" in the app
# launcher is the Web UI (dsh-web user service) in a Chrome app window.
{ pkgs, ... }:
let
  port = "3080";

  # dsh boot needs node-addon-require-builtin, which locates private Node state
  # by pattern-matching the binary. It only recognizes the official nodejs.org
  # builds; every nixpkgs nodejs fails with Unsupported/no-getter.
  nodeOfficial = pkgs.stdenv.mkDerivation rec {
    pname = "nodejs-official";
    version = "24.19.0";
    src = pkgs.fetchurl {
      url = "https://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.xz";
      hash = "sha256-FLNC5xIE+BG95hU76OBLYq72PCNv75K1X5yDFUtAlkc=";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    installPhase = ''
      mkdir -p $out
      cp -a bin include lib share $out/
    '';
  };

  dshUpdate = pkgs.writeShellApplication {
    name = "dsh-update";
    runtimeInputs = with pkgs; [
      coreutils
      nodeOfficial
      systemd
      util-linux
    ];
    text = ''
      check=0
      if [ "''${1:-}" = "--check" ]; then
        check=1
        shift
      fi
      spec=''${1:-latest}

      root=''${XDG_DATA_HOME:-$HOME/.local/share}/dsh
      mkdir -p "$root"
      exec 9> "$root/.update.lock"
      flock 9

      pkg_json=$root/node_modules/@deepseek-ai/dsh/package.json
      current=none
      if [ -f "$pkg_json" ]; then
        current=$(node -p "require(process.argv[1]).version" "$pkg_json")
      fi
      target=$(npm view "@deepseek-ai/dsh@$spec" version | tail -n 1)
      if [ -z "$target" ]; then
        echo "dsh-update: no version for @deepseek-ai/dsh@$spec" >&2
        exit 1
      fi

      echo "dsh: installed $current, $spec is $target"
      echo "     https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v$target"
      if [ "$current" = "$target" ]; then
        echo "dsh: up to date"
        exit 0
      fi
      if [ "$check" = 1 ]; then
        exit 0
      fi

      npm install --prefix "$root" --save-exact --no-audit --no-fund "@deepseek-ai/dsh@$target"
      echo "dsh: $current -> $target"
      systemctl --user try-restart dsh-web.service || true
    '';
  };

  dsh = pkgs.writeShellScriptBin "dsh" ''
    bin="''${XDG_DATA_HOME:-$HOME/.local/share}/dsh/node_modules/.bin/dsh"
    if [ ! -x "$bin" ]; then
      ${dshUpdate}/bin/dsh-update || exit 1
    fi
    export PATH="${
      pkgs.lib.makeBinPath [
        nodeOfficial
        pkgs.pnpm
      ]
    }:$PATH"
    exec "$bin" "$@"
  '';

  dshDesktop = pkgs.writeShellApplication {
    name = "dsh-desktop";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      systemd
    ];
    text = ''
      # The Web UI requires the per-launch ?token= URL that dsh web prints.
      systemctl --user start dsh-web.service
      invocation=$(systemctl --user show -p InvocationID --value dsh-web.service)
      url=
      for _ in $(seq 240); do
        url=$(journalctl --user -o cat "_SYSTEMD_INVOCATION_ID=$invocation" \
          | grep -o 'http://127\.0\.0\.1:${port}/?token=[A-Za-z0-9_-]*' | tail -n 1 || true)
        [ -n "$url" ] && break
        sleep 0.5
      done
      if [ -z "$url" ]; then
        echo "dsh-desktop: dsh-web did not print its URL; see journalctl --user -u dsh-web" >&2
        exit 1
      fi
      exec ${pkgs.google-chrome}/bin/google-chrome-stable --password-store=basic --app="$url" "$@"
    '';
  };
in
{
  home.packages = [
    dsh
    dshUpdate
    dshDesktop
  ];

  systemd.user.services.dsh-web = {
    Unit.Description = "DeepSeek Harness Web UI";
    Service = {
      WorkingDirectory = "%h";
      Environment = [
        "PATH=%h/.local/bin:/run/wrappers/bin:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
      ];
      ExecStart = "${dsh}/bin/dsh web --no-open --port ${port}";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  xdg.desktopEntries.dsh = {
    name = "DeepSeek Harness";
    comment = "DeepSeek Harness Web UI";
    exec = "${dshDesktop}/bin/dsh-desktop";
    terminal = false;
    categories = [ "Development" ];
  };
}
