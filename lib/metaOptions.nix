# metaOptions — shared type definitions for the kdk.meta registry.
#
# Used by both NixOS-level and home-manager-level meta declarations.
# Provides submodule types for module and profile metadata entries.
{ lib }:

let
  moduleEntry = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Module name";
      };
      namespace = lib.mkOption {
        type = lib.types.str;
        description = "Dot-separated namespace (e.g. kdk.modules, kdk.home)";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Human-readable description";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "other";
        description = "Category for grouping in TUI";
      };
      deps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Module dependencies (auto-enabled)";
      };
      enabled = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this module is currently enabled (resolved)";
      };
    };
  };

  profileEntry = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Profile name";
      };
      namespace = lib.mkOption {
        type = lib.types.str;
        description = "Dot-separated namespace (e.g. kdk.profiles)";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Human-readable description";
      };
      modules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Modules enabled by this profile";
      };
      enabled = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this profile is currently enabled";
      };
    };
  };
in
{
  mkMetaOptions = {
    modules = lib.mkOption {
      type = lib.types.attrsOf moduleEntry;
      default = { };
      description = "Registry of all modules and their metadata";
    };
    profiles = lib.mkOption {
      type = lib.types.attrsOf profileEntry;
      default = { };
      description = "Registry of all profiles and their metadata";
    };
  };
}
