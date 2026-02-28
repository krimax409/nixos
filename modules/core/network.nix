import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "network";
  description = "NetworkManager, firewall, proxy";
  category = "system";
  cfg =
    _cfg:
    { pkgs, host, ... }:
    {
      networking = {
        hostName = "${host}";
        networkmanager.enable = true;
        nameservers = [
          "8.8.8.8"
          "8.8.4.4"
          "1.1.1.1"
        ];
        firewall = {
          enable = true;
          allowedTCPPorts = [
            22
            80
            443
            2080
            59010
            59011
          ];
          allowedUDPPorts = [
            59010
            59011
          ];
        };
      };

      programs.throne = {
        enable = true;
        tunMode.enable = true;
      };

      environment.systemPackages = with pkgs; [ networkmanagerapplet ];
    };
}
