{ pkgs, inputs, ... }:
let
  claude-code-latest = inputs.claude-code-nix.packages.${pkgs.system}.default;
  claude-proxied = pkgs.writeShellApplication {
    name = "claude-proxied";
    runtimeInputs = [ claude-code-latest ];
    text = ''
      export HTTPS_PROXY="http://127.0.0.1:1081"
      export HTTP_PROXY="http://127.0.0.1:1081"
      # локалка и loopback идут в обход прокси
      export NO_PROXY="localhost,127.0.0.1,::1,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
      exec ${claude-code-latest}/bin/claude "$@"
    '';
  };
in
{
  nixpkgs.config.allowUnfree = true;

  # Устанавливаем только враппер; сам claude попадёт в PATH через runtimeInputs
  home.packages = [ claude-proxied ];

  # (Необязательно) Делаем удобный алиас, чтобы команда была просто `claude`
  programs.zsh.enable = true;
  programs.zsh.shellAliases.claude = "claude-proxied";
  # для bash можно так:
  # programs.bash.enable = true;
  # programs.bash.shellAliases.claude = "claude-proxied";
}
