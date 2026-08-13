{ host, lib, sshLanInterface ? null, ... }:
{
  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
    };

    openssh = {
      enable = true;
      openFirewall = false;
      ports = [ 22 ] ++ lib.optional (host == "laptop") 2222;

      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  # SSH is restricted to Tailscale and each host's trusted LAN interface.
  # Laptop also listens on 2222 over tailscale0 as a migration fallback.
  networking.firewall.interfaces = {
    tailscale0.allowedTCPPorts = [ 22 ] ++ lib.optional (host == "laptop") 2222;
  }
  // lib.optionalAttrs (sshLanInterface != null) {
    "${sshLanInterface}".allowedTCPPorts = [ 22 ];
  };
}
