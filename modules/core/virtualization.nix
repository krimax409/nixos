{ pkgs, username, ... }:
{
  users.users.${username}.extraGroups = [
    "docker"
    "libvirtd"
  ];

  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    win-spice
  ];

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
    };

    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
}
