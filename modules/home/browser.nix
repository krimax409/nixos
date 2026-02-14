{ inputs, pkgs, ... }:
let
  chrome-wrapper = pkgs.writeShellApplication {
    name = "google-chrome-stable";
    runtimeInputs = [ pkgs.bash ];
    text = ''
      PROXY_ARGS=()
      if timeout 1 bash -c '>/dev/tcp/127.0.0.1/2080' 2>/dev/null; then
        PROXY_ARGS=(
          "--proxy-server=http://127.0.0.1:2080"
          "--proxy-bypass-list=localhost;127.0.0.1;10.*;192.168.*;*.local;*.google.com;*.googleapis.com;*.gstatic.com;*.google.ru;accounts.google.com"
        )
      fi
      exec ${pkgs.google-chrome}/bin/google-chrome-stable "''${PROXY_ARGS[@]}" "$@"
    '';
  };

  chrome-with-proxy = pkgs.symlinkJoin {
    name = "google-chrome-with-proxy";
    paths = [
      chrome-wrapper
      pkgs.google-chrome
    ];
  };
in
{
  home.packages = [
    inputs.zen-browser.packages.${pkgs.system}.default
    pkgs.firefox
    chrome-with-proxy
  ];
}
