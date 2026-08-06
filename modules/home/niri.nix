{
  config,
  configRoot,
  host,
  inputs,
  pkgs,
  ...
}:
let
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.noctalia = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../../patches/noctalia-taskbar-indicator-offset.patch ];
    });
  };

  xdg.configFile = {
    "niri/config.kdl" = {
      source = outOfStore "${configRoot}/configs/niri/${host}.kdl";
      force = true;
    };
    "niri/common.kdl" = {
      source = outOfStore "${configRoot}/configs/niri/common.kdl";
      force = true;
    };
    "noctalia/config.toml" = {
      source = outOfStore "${configRoot}/configs/noctalia/config.toml";
      force = true;
    };
    "noctalia/palettes/windows-dark.json" = {
      source = outOfStore "${configRoot}/configs/noctalia/palettes/windows-dark.json";
      force = true;
    };
  };

  xdg.stateFile."noctalia/settings.toml" = {
    source = outOfStore "${configRoot}/configs/noctalia/${host}/settings.toml";
    force = true;
  };
}
