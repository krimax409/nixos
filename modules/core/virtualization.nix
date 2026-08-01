{ pkgs, username, ... }:
{
  users.users.${username}.extraGroups = [ "libvirtd" ];

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
