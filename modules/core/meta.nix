# Declares kdk.meta options at the NixOS level and aggregates
# home-manager module metadata into the top-level registry.
#
# Query: nix eval .#nixosConfigurations.desktop.config.kdk.meta --json
{
  config,
  lib,
  username,
  ...
}:
let
  metaOptions = import ../../lib/metaOptions.nix { inherit lib; };
  hmMeta = config.home-manager.users.${username}.kdk.meta;
in
{
  options.kdk.meta = metaOptions.mkMetaOptions;

  config.kdk.meta = {
    modules = hmMeta.modules;
    profiles = hmMeta.profiles;
  };
}
