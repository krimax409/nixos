{
  description = "KDK NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    codex-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    noctalia = {
      url = "github:noctalia-dev/noctalia/v5.0.0-beta.7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      configRoot = "/etc/nixos/nixos-config";
      username = "k";
      system = "x86_64-linux";
      mkHost =
        host:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ (./hosts + "/${host}") ];
          specialArgs = {
            inherit
              configRoot
              host
              inputs
              username
              ;
          };
        };
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop";
        laptop = mkHost "laptop";
      };
    };
}
