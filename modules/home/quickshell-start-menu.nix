{
  config,
  configRoot,
  ...
}:
let
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.quickshell = {
    enable = true;
    activeConfig = "win11-start-menu";
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
    configs.win11-start-menu = outOfStore "${configRoot}/configs/quickshell/win11-start-menu";
  };
}
