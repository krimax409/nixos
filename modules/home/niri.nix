{
  config,
  configRoot,
  host,
  ...
}:
let
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.noctalia.enable = true;

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
  };

  xdg.stateFile."noctalia/settings.toml" = {
    source = outOfStore "${configRoot}/configs/noctalia/${host}/settings.toml";
    force = true;
  };
}
