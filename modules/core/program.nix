import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "program";
  description = "Core programs: dconf, zsh, gnupg, nix-ld";
  category = "system";
  cfg =
    _cfg:
    { ... }:
    {
      programs.dconf.enable = true;
      programs.zsh.enable = true;
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
      programs.nix-ld.enable = true;
    };
}
