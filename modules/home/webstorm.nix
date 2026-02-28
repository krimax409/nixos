import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "webstorm";
  description = "JetBrains WebStorm IDE";
  category = "development";

  cfg =
    _cfg:
    { pkgs, ... }:
    let
      fetchWithProxy = import ../../lib/fetch-with-proxy.nix { inherit pkgs; };
    in
    {
      home.packages = [
        (pkgs.jetbrains.webstorm.overrideAttrs (old: {
          src = fetchWithProxy old.src;
        }))
      ];
    };
}
