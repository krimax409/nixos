# Declares kdk.meta options within the home-manager evaluation context.
# Home modules (via mkModule) write their metadata here.
# The NixOS-level modules/core/meta.nix aggregates this into top-level kdk.meta.
{ lib, ... }:
let
  metaOptions = import ../../lib/metaOptions.nix { inherit lib; };
in
{
  options.kdk.meta = metaOptions.mkMetaOptions;
}
