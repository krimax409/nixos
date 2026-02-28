import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "virtualization";
  description = "QEMU/KVM with virt-manager";
  category = "system";
  cfg =
    _cfg:
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
        adwaita-icon-theme
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
    };
}
