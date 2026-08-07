{ pkgs, ... }:
{
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };
  programs.nix-ld = {
    enable = true;
    # GUI-библиотеки для Electron-приложений (Hermes Desktop и подобных)
    libraries = with pkgs; [
      gtk3
      nss
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
      libxkbcommon
      libdrm
      libgbm
      alsa-lib
      at-spi2-atk
      cups
      pango
      cairo
      expat
      nspr
      dbus
      gdk-pixbuf
      glib
    ];
  };
}
