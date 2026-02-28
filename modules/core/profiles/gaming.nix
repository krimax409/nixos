import ../../../lib/mkProfile.nix {
  namespace = "kdk.profiles";
  modulesNamespace = "kdk.modules";
  name = "gaming";
  description = "NVIDIA GPU and Steam gaming";
  modules = [
    "steam"
    "nvidia"
  ];
}
