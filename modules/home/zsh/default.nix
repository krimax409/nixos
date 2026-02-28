{ config, lib, ... }:
{
  imports = [
    ./zsh.nix
    ./zsh_alias.nix
    ./zsh_keybinds.nix
  ];

  options.kdk.home.zsh = {
    enable = lib.mkEnableOption "the zsh module";
  };

  config.kdk.meta.modules."kdk.home.zsh" = {
    name = "zsh";
    namespace = "kdk.home";
    description = "Zsh shell with plugins";
    category = "terminal";
    deps = [ ];
    enabled = config.kdk.home.zsh.enable;
  };
}
