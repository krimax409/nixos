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

  # SSH is restricted to trusted interfaces only; port 22 is not open globally.
  # Desktop also exposes port 22 on enp8s0 as a LAN break-glass path.
  networking.firewall.interfaces = {
    tailscale0.allowedTCPPorts = [ 22 ] ++ lib.optional (host == "laptop") 2222;
  }
  // lib.optionalAttrs (sshLanInterface != null) {
    "${sshLanInterface}".allowedTCPPorts = [ 22 ];
  };
}
