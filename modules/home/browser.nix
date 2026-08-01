{
  config,
  configRoot,
  lib,
  pkgs,
  ...
}:
let
  proxyAddress = "127.0.0.1:2080";
  pacAddress = "127.0.0.1";
  pacPort = 18765;
  pacUrl = "http://${pacAddress}:${toString pacPort}/throne.pac";

  mkBrowser =
    {
      desktopId,
      executable,
      icon,
      name,
      package,
      startupWMClass,
    }:
    let
      binary = "${package}/bin/${executable}";
      mkWrapper =
        suffix: proxyArgs:
        pkgs.writeShellApplication {
          name = "${desktopId}-${suffix}";
          text = ''
            exec ${binary} ${lib.escapeShellArgs proxyArgs} "$@"
          '';
        };
      wrappers = {
        auto = mkWrapper "auto" [ "--proxy-pac-url=${pacUrl}" ];
        proxy = mkWrapper "proxy" [ "--proxy-server=http://${proxyAddress}" ];
        direct = mkWrapper "direct" [ "--no-proxy-server" ];
      };
      mkEntry =
        {
          comment,
          displayName,
          wrapper,
          mimeType ? null,
        }:
        {
          name = displayName;
          genericName = "Web Browser";
          inherit comment icon mimeType;
          exec = "${wrapper}/bin/${wrapper.name} %U";
          terminal = false;
          categories = [
            "Network"
            "WebBrowser"
          ];
          settings.StartupWMClass = startupWMClass;
          actions = {
            new-window = {
              name = "New Window";
              exec = "${wrapper}/bin/${wrapper.name}";
            };
            incognito = {
              name = "New Incognito Window";
              exec = "${wrapper}/bin/${wrapper.name} --incognito";
            };
          };
        };
    in
    {
      packages = [
        package
        wrappers.auto
        wrappers.proxy
        wrappers.direct
      ];
      entries = {
        "${desktopId}" = mkEntry {
          displayName = name;
          comment = "Use Throne when available, otherwise connect directly";
          wrapper = wrappers.auto;
          mimeType = [
            "text/html"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
          ];
        };
        "${desktopId}-proxy" = mkEntry {
          displayName = "${name} (Proxy Only)";
          comment = "Always use the local Throne proxy";
          wrapper = wrappers.proxy;
        };
        "${desktopId}-direct" = mkEntry {
          displayName = "${name} (Direct)";
          comment = "Connect directly without a proxy";
          wrapper = wrappers.direct;
        };
      };
    };

  chrome = mkBrowser {
    desktopId = "google-chrome";
    executable = "google-chrome-stable";
    icon = "google-chrome";
    name = "Google Chrome";
    package = pkgs.google-chrome;
    startupWMClass = "Google-chrome";
  };
  brave = mkBrowser {
    desktopId = "brave-browser";
    executable = "brave";
    icon = "brave-browser";
    name = "Brave";
    package = pkgs.brave;
    startupWMClass = "brave-browser";
  };
in
{
  home.packages = [ pkgs.firefox ] ++ chrome.packages ++ brave.packages;

  xdg.configFile."proxy/throne.pac" = {
    source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/configs/proxy/throne.pac";
    force = true;
  };

  systemd.user.services.throne-pac = {
    Unit = {
      Description = "Serve the Throne PAC file to Chromium browsers";
      After = [ "nixos-activation.service" ];
    };
    Service = {
      ExecStart = "${pkgs.darkhttpd}/bin/darkhttpd ${config.xdg.configHome}/proxy --addr ${pacAddress} --port ${toString pacPort} --no-listing";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "default.target" ];
  };

  xdg.desktopEntries =
    chrome.entries
    // brave.entries
    // {
      "com.google.Chrome" = {
        name = "Google Chrome";
        noDisplay = true;
      };
      "com.brave.Browser" = {
        name = "Brave";
        noDisplay = true;
      };
    };
}
