{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;

    config = {
      warn_timeout = "1h";
    };
  };

  # Silence direnv's per-directory export chatter.
  home.sessionVariables.DIRENV_LOG_FORMAT = "";
}
