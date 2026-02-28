import ../../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "superfile";
  description = "Terminal file manager";
  category = "terminal";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ superfile ];
      xdg.configFile."superfile/config.toml".source = ./config.toml;
    };
}
