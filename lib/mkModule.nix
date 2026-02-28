# mkModule — factory function for creating toggleable NixOS/Home-Manager modules.
#
# Usage (module file is just an import):
#   import ../../lib/mkModule.nix {
#     namespace = "kdk.modules";  # or "kdk.home"
#     name = "steam";
#     description = "Steam with Proton-GE and GameScope";
#     category = "gaming";
#     deps = [ "nvidia" ];
#     extraOpts = { };
#     cfg = moduleCfg: { config, lib, pkgs, ... }: { ... };
#   }
#
# Returns a standard NixOS module function that receives all module args.
# Note: pkgs must be passed via specialArgs in flake.nix.
{
  namespace,
  name,
  description ? "",
  category ? "other",
  deps ? [ ],
  extraOpts ? { },
  cfg,
}:

{ config, lib, ... }@args:
let
  nsPath = lib.splitString "." namespace;
  moduleCfg = lib.getAttrFromPath (nsPath ++ [ name ]) config;

  depEnables = builtins.listToAttrs (
    map (dep: {
      name = dep;
      value = {
        enable = true;
      };
    }) deps
  );
in
{
  options = lib.setAttrByPath (nsPath ++ [ name ]) (
    { enable = lib.mkEnableOption "the ${name} module"; } // extraOpts
  );

  config = lib.mkMerge [
    # Meta registration — unconditional, outside mkIf.
    # Provides module metadata for TUI discovery via nix eval.
    {
      kdk.meta.modules."${namespace}.${name}" = {
        inherit
          name
          namespace
          description
          category
          deps
          ;
        enabled = moduleCfg.enable;
      };
    }

    # Module configuration — only applied when enabled.
    (lib.mkIf moduleCfg.enable (
      lib.mkMerge [
        (lib.optionalAttrs (deps != [ ]) (lib.setAttrByPath nsPath depEnables))
        (cfg moduleCfg args)
      ]
    ))
  ];
}
