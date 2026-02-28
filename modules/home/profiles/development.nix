import ../../../lib/mkProfile.nix {
  namespace = "kdk.homeProfiles";
  modulesNamespace = "kdk.home";
  name = "development";
  description = "IDEs and programming tools";
  modules = [
    "git"
    "lazygit"
    "nvim"
    "webstorm"
    "rider"
    "packages-dev"
  ];
}
