{ pkgs, username, ... }:
{
  systemd.services.zapret-diy = {
    description = "Zapret DPI bypass";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [
      bash
      coreutils
      iptables
      nix
      curl
      gnutar
      gzip
      iproute2
      kmod
      zapret
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "/home/${username}/zapret-diy/zapret.sh service-start";
      ExecStopPost = "/home/${username}/zapret-diy/zapret.sh service-stop";
      Restart = "no";
      AmbientCapabilities = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
      ];
    };
  };
}
