# mkProfile — factory function for creating module bundle profiles.
#
# Usage (module file is just an import):
#   import ../../../lib/mkProfile.nix {
#     namespace = "kdk.profiles";
#     modulesNamespace = "kdk.modules";
#     name = "gaming";
#     description = "NVIDIA GPU and Steam gaming";
#     modules = [ "steam" "nvidia" ];
#   }
#
# Returns a standard NixOS module function.
{
  namespace,
  modulesNamespace,
  name,
  description ? "",
  modules ? [ ],
}:

{ config, lib, ... }:
let
  nsPath = lib.splitString "." namespace;
  modsNsPath = lib.splitString "." modulesNamespace;
  profileCfg = lib.getAttrFromPath (nsPath ++ [ name ]) config;

  moduleEnables = builtins.listToAttrs (
    map (mod: {
      name = mod;
      value = {
        enable = true;
      };
    }) modules
  );
in
{
  options = lib.setAttrByPath (nsPath ++ [ name ]) {
    enable = lib.mkEnableOption "the ${name} profile";
  };

  config = lib.mkMerge [
    # Meta registration — unconditional.
    {
      kdk.meta.profiles."${namespace}.${name}" = {
        inherit
          name
          namespace
          description
          modules
          ;
        enabled = profileCfg.enable;
      };
    }

    # Profile activation — only when enabled.
    (lib.mkIf profileCfg.enable (lib.setAttrByPath modsNsPath moduleEnables))
  ];
}
