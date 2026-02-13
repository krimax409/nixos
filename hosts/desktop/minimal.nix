{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "desktop";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Desktop
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # User
  users.users.k = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Packages
  environment.systemPackages = with pkgs; [
    firefox
    nodejs_22  # for claude code
    git
    wget
    appimage-run  # for Throne
  ];

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  powerManagement.cpuFreqGovernor = "performance";
  system.stateVersion = "24.05";
}