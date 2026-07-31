{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Emulation
    sameboy
    snes9x
  ];
}
