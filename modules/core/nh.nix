{ host, pkgs, ... }:
{
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = "/etc/nixos/nixos-config#${host}";
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nvd
  ];
}
