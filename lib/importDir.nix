# importDir — auto-import all NixOS modules from a directory.
#
# Scans a directory and returns a list of import paths:
# - All .nix files except default.nix
# - All subdirectories containing a default.nix
#
# Usage:
#   imports = importDir ./.;
#   imports = (importDir ./.) ++ (importDir ./profiles);
{ lib }:

dir:
let
  contents = builtins.readDir dir;

  isNixFile =
    name: type:
    type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";

  isModuleDir =
    name: type:
    type == "directory" && builtins.pathExists (dir + "/${name}/default.nix");

  nixFiles = lib.filterAttrs isNixFile contents;
  moduleDirs = lib.filterAttrs isModuleDir contents;

  filePaths = lib.mapAttrsToList (name: _: dir + "/${name}") nixFiles;
  dirPaths = lib.mapAttrsToList (name: _: dir + "/${name}") moduleDirs;
in
filePaths ++ dirPaths
