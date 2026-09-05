{
  config,
  configRoot,
  ...
}:
let
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file.".grok/config.toml" = {
    source = outOfStore "${configRoot}/configs/grok/config.toml";
    force = true;
  };
}
