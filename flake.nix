{
  description = "KDK NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    codex-nixpkgs.url = "github:NixOS/nixpkgs/master";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:herdrdev/herdr/v0.9.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/v5.0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nub = {
      url = "github:nubjs/nub/v0.9.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    purple = {
      url = "github:erickochen/purple";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fastpotify = {
      url = "github:crmne/fastpotify/v0.7.1";
    };

    raspberryDesktop = {
      url = "github:mazda1337/raspberry-desktop/raspberry";
      flake = false;
    };

    nixcord = {
      url = "github:4evy/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    flake-utils.url = "github:numtide/flake-utils/v1.0.0";

    dbx = {
      url = "github:t8y2/dbx";
      inputs.flake-utils.follows = "flake-utils";
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
      system = "x86_64-linux";
      hostSettings = {
        desktop = {
          hostname = "desktop";
          username = "k";
          systemStateVersion = "24.05";
          homeStateVersion = "24.05";
          sshLanInterface = "enp8s0";
          configRoot = "/home/k/src/nixos-config";
        };
        laptop = {
          hostname = "nixos";
          username = "krim";
          systemStateVersion = "25.11";
          homeStateVersion = "25.11";
          sshLanInterface = "wlp3s0";
          configRoot = "/etc/nixos";
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
            inherit host inputs;
            configRoot = settings.configRoot;
            inherit (settings)
              hostname
              username
              systemStateVersion
              homeStateVersion
              sshLanInterface
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
