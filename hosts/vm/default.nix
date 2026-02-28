{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./toggles.nix
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = lib.mkForce "/dev/vda";
  boot.loader.grub.useOSProber = lib.mkForce false;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      PermitRootLogin = "yes";
    };
  };
}
