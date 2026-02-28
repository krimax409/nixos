import ../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "retroarch";
  description = "RetroArch emulator frontend";
  category = "gaming";

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = (
        with pkgs;
        [
          # (retroarch.override {
          #   cores = with libretro; [
          #     fceumm
          #     gambatte
          #     mgba
          #     snes9x
          #   ];
          # })
        ]
      );
    };
}
