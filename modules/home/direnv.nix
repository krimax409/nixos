{ pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;

    config = {
      warn_timeout = "1h";
    };
  };

  # Silence direnv output by default
  programs.zsh.initExtra = ''
    export DIRENV_LOG_FORMAT=""
  '';
}
