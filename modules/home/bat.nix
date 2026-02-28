import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "bat";
  description = "Cat clone with syntax highlighting";
  category = "terminal";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      programs.bat = {
        enable = true;
        config = {
          pager = "less -FR";
          theme = "gruvbox-dark";
        };
        extraPackages = with pkgs.bat-extras; [
          batman
          batpipe
          batgrep
          # batdiff
        ];
      };
    };
}
