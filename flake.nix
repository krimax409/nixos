{
  description = "KDK NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    codex-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:herdrdev/herdr/v0.8.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/v5.0.0-beta.7";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nub = {
      url = "github:nubjs/nub/v0.7.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Remove this source input once Throne 1.2.2 reaches nixos-unstable.
    throne-nixpkgs = {
      url = "github:TomaSajt/nixpkgs/0cbdc25b4df6051689052125cb550485f09dfb59";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      configRoot = "/etc/nixos/nixos-config";
      system = "x86_64-linux";
      hostSettings = {
        desktop = {
          hostname = "desktop";
          username = "k";
          systemStateVersion = "24.05";
          homeStateVersion = "24.05";
          sshLanInterface = "enp8s0";
        };
        laptop = {
          hostname = "nixos";
          username = "krim";
          systemStateVersion = "25.11";
          homeStateVersion = "25.11";
          sshLanInterface = "wlp3s0";
        };
      };
      mkHost =
        host:
        let
          settings = hostSettings.${host};
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ (./hosts + "/${host}") ];
          specialArgs = {
            inherit configRoot host inputs;
            inherit (settings) hostname username systemStateVersion homeStateVersion sshLanInterface;
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
