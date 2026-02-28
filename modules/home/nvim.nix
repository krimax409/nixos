import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "nvim";
  description = "Neovim editor";
  category = "development";

  cfg =
    _cfg:
    { ... }:
    {
      programs.neovim = {
        enable = true;
        vimAlias = true;
      };
    };
}
