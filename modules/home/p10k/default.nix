import ../../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "p10k";
  description = "Powerlevel10k Zsh theme";
  category = "terminal";
  deps = [ "zsh" ];

  cfg =
    _cfg:
    { ... }:
    {
      home.file.".p10k.zsh".source = ./.p10k.zsh;
    };
}
