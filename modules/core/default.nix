{ lib, ... }:
let
  importDir = import ../../lib/importDir.nix { inherit lib; };
in
{
  imports = (importDir ./.) ++ (importDir ./profiles);
}
