{ pkgs, ... }:
let
  # Временно отключено - ошибка компиляции с signal handler
  # _2048 = pkgs.callPackage ../../../pkgs/2048/default.nix { };
in
{
  home.packages = [
    # _2048
  ];
}
