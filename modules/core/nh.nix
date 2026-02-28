import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "nh";
  description = "Nix helper with auto garbage collection";
  category = "system";
  cfg =
    _cfg:
    { pkgs, ... }:
    {
      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep-since 7d --keep 5";
        };
        flake = "/etc/nixos/nixos-config";
      };

      environment.systemPackages = with pkgs; [
        nix-output-monitor
        nvd
      ];
    };
}
