import ../../../lib/mkProfile.nix {
  namespace = "kdk.homeProfiles";
  modulesNamespace = "kdk.home";
  name = "base";
  description = "Shell, editors, CLI tools";
  modules = [
    "bat"
    "btop"
    "fastfetch"
    "fzf"
    "gtk"
    "kitty"
    "micro"
    "nvim"
    "p10k"
    "scripts"
    "ssh"
    "xdg-mimes"
    "zsh"
    "packages-cli"
  ];
}
