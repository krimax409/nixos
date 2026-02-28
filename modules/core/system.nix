import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "system";
  description = "Nix settings, fonts, locale, timezone";
  category = "system";
  cfg =
    _cfg:
    { pkgs, ... }:
    {
      nix = {
        settings = {
          auto-optimise-store = true;
          experimental-features = [
            "nix-command"
            "flakes"
            "pipe-operators"
          ];
          substituters = [ "https://cache.nixos.org" ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];
          max-jobs = "auto";
          cores = 0;
          connect-timeout = 5;
        };
      };

      environment.systemPackages = with pkgs; [
        wget
        git
        vscode
      ];

      fonts.fontconfig.defaultFonts = {
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        monospace = [ "Maple Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };

      time.timeZone = "Europe/Moscow";
      i18n.defaultLocale = "en_US.UTF-8";
      system.stateVersion = "24.05";
    };
}
