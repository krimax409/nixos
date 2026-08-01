{ pkgs, ... }:
{
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };
  programs.nix-ld.enable = true;
}
