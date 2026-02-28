import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "steam";
  description = "Steam with Proton-GE and GameScope";
  category = "gaming";
  deps = [ "nvidia" ];

  cfg =
    _cfg:
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        mangohud
        protonup-ng
      ];
      programs = {
        steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = false;
          gamescopeSession.enable = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
        };
        gamemode.enable = true;
        gamescope = {
          enable = true;
          capSysNice = true;
          args = [
            "--rt"
            "--expose-wayland"
          ];
        };
      };
    };
}
