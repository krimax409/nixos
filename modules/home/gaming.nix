import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "gaming";
  description = "Retro emulators: SameBoy, Snes9x";
  category = "gaming";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        ## Emulation
        sameboy
        snes9x
      ];
    };
}
