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
        1080
        1081
        59010
        59011
      ];
      allowedUDPPorts = [
        59010
        59011
      ];
    };
  };

  services.sing-box = {
    enable = true;
    package = pkgs.sing-box;

    settings = {
      log = {
        level = "info";
      };

      inbounds = [
        {
          type = "socks";
          tag = "socks-in";
          listen = "127.0.0.1";
          listen_port = 1080;
        }
        {
          type = "http";
          tag = "http-in";
          listen = "127.0.0.1";
          listen_port = 1081;
        }
      ];

      outbounds = [
        {
          type = "vless";
          tag = "redpiped";
          server = "lori.piped.wavycat.me";
          server_port = 443;
          uuid = "b966c6c6-e249-493d-8521-22fe08e0854b";
          flow = "xtls-rprx-vision";

          tls = {
            enabled = true;
            server_name = "gate.piped.wavycat.me";

            ## fingerprint -> utls
            utls = {
              enabled = true;
              fingerprint = "chrome";
            };

            ## Reality
            reality = {
              enabled = true;
              public_key = "oOxqR65N62xYCH2b-oZb0tHZaPI1yUDHl7S4KUBzvjo";
              short_id = "5e233aa39554d080";
            };
          };
        }

        {
          type = "direct";
          tag = "direct";
        }
        {
          type = "block";
          tag = "block";
        }
      ];

      route = {
        auto_detect_interface = true;
        rules = [
          {
            outbound = "direct";
            ip_is_private = true;
          }
          { outbound = "redpiped"; }
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [ networkmanagerapplet ];
}
