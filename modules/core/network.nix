{
  host,
  inputs,
  pkgs,
  ...
}:
let
  throne = pkgs.callPackage "${inputs.throne-nixpkgs}/pkgs/by-name/th/throne/package.nix" { };
in
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
    package = throne;
    tunMode.enable = false;
  };
}
