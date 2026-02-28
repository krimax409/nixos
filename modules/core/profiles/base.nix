import ../../../lib/mkProfile.nix {
  namespace = "kdk.profiles";
  modulesNamespace = "kdk.modules";
  name = "base";
  description = "Essential system: boot, audio, network";
  modules = [
    "bootloader"
    "hardware"
    "xserver"
    "network"
    "nh"
    "pipewire"
    "program"
    "security"
    "services"
    "sudo"
    "system"
    "wayland"
    "zapret"
  ];
}
