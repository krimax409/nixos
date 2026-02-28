import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "obsidian";
  description = "Note-taking app";
  category = "utility";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ obsidian ];
    };
}
