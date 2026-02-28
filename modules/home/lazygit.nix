import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "lazygit";
  description = "Terminal UI for Git";
  category = "development";
  deps = [ "git" ];

  cfg =
    _cfg:
    { ... }:
    {
      programs.lazygit = {
        enable = true;

        settings = {
          gui.border = "single";
        };
      };
    };
}
