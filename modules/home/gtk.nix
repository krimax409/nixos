{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    nerd-fonts.symbols-only
    twemoji-color-font
    noto-fonts-color-emoji
    noto-fonts
    fantasque-sans-mono
    maple-mono.truetype-autohint
  ];

  gtk = {
    enable = true;
    font = {
      name = "Noto Sans";
      size = 11;
    };
    theme = {
      name = "Colloid-Green-Dark-Gruvbox";
      package = pkgs.colloid-gtk-theme.override {
        colorVariants = [ "dark" ];
        themeVariants = [ "green" ];
        tweaks = [
          "gruvbox"
          "rimless"
          "float"
        ];
      };
    };
    iconTheme = {
      # Временно используем Adwaita вместо Papirus - слишком долго собирается
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      # name = "Papirus-Dark";
      # package = pkgs.papirus-icon-theme.override { color = "black"; };
    };
    cursorTheme = {
      name = "Posy_Cursor";
      package = pkgs.posy-cursors;
      size = 24;
    };
  };
  home.pointerCursor = {
    name = "Posy_Cursor";
    package = pkgs.posy-cursors;
    size = 24;
  };
}
