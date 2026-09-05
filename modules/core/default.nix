{ pkgs, inputs, ... }:
{
  sops.defaultSopsFile = ../../secrets/infisical.yaml;
  sops.age.keyFile = "/home/k/.config/sops/age/keys.txt";
  sops.secrets.infisical-env = {
    owner = "k";
    group = "users";
    mode = "0400";
    path = "/run/secrets/infisical.env";
    format = "yaml";
    key = "INFISICAL_CLIENT_ID";
  };
  sops.secrets.infisical-secret = {
    owner = "k";
    group = "users";
    mode = "0400";
    path = "/run/secrets/infisical.secret";
    format = "yaml";
    key = "INFISICAL_CLIENT_SECRET";
  };
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./envfs.nix
    ./hermes-discord-backup.nix
    ./flatpak.nix
    ./hardware.nix
    ./memory.nix
    ./network.nix
    ./nh.nix
    ./niri.nix
    ./pipewire.nix
    ./program.nix
    ./security.nix
    ./services.nix
    ./steam.nix
    ./sudo.nix
    ./system.nix
    ./tailscale.nix
    ./user.nix
  ];
}
