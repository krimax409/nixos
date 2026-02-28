import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "flow";
  description = "Flow launcher";
  category = "utility";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.flow-control ];
    };
}
