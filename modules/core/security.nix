import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "security";
  description = "Security: rtkit, PAM for screen lockers";
  category = "system";
  cfg =
    _cfg:
    { ... }:
    {
      security.rtkit.enable = true;
      security.sudo.enable = true;
      security.pam.services.kde = { };
    };
}
