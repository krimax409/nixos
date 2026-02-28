import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "zapret";
  description = "DPI bypass service";
  category = "system";
  cfg =
    _cfg:
    { pkgs, ... }:
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
          ExecStart = "/home/k/zapret-diy/zapret.sh service-start";
          ExecStopPost = "/home/k/zapret-diy/zapret.sh service-stop";
          Restart = "no";
          AmbientCapabilities = [
            "CAP_NET_ADMIN"
            "CAP_NET_RAW"
          ];
        };
      };
    };
}
