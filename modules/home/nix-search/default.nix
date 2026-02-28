import ../../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "nix-search";
  description = "Interactive Nix package search";
  category = "utility";

  cfg =
    _cfg:
    { pkgs, ... }:
    let
      nsearch = pkgs.writeShellScriptBin "nsearch" (
        builtins.readFile ./nix-search.sh
      );
    in
    {
      home.packages = with pkgs; [
        nix-search-tv
        nsearch
      ];
      xdg.configFile."nix-search-tv/config.json".source = ./config.json;
    };
}
