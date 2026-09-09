{ config, lib, ... }:
let
  bitwardenSocket = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
  preferBitwardenAgent = ''
    if [[ -z "''${SSH_CONNECTION-}" && -S "${bitwardenSocket}" ]]; then
      export SSH_AUTH_SOCK="${bitwardenSocket}"
    fi
  '';
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # Отключаем дефолтные настройки как рекомендовано

    settings = {
      "*" = {
        AddKeysToAgent = "1h";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/control-%r@%h:%p";
        ControlPersist = "10m";
      };
      "github.com" = {
        HostName = "ssh.github.com";
        User = "git";
        Port = 443;
        IdentityFile = "~/.ssh/id_github";
        IdentitiesOnly = true;
      };
    };

    matchBlocks = {
      "colombino" = {
        hostname = "65.21.127.112";
        user = "webdev";
        identityFile = "~/.ssh/id_ed25519";
      };
      "jump" = {
        hostname = "138.124.13.10";
        user = "root";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
      "politmine_backend" = {
        hostname = "144.76.36.70";
        port = 1212;
        user = "politmine_backend";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
        proxyJump = "jump";
      };
      "politmine_frontend" = {
        hostname = "144.76.36.70";
        port = 1212;
        user = "politmine_frontend";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
        proxyJump = "jump";
      };
      "hermes" = {
        hostname = "192.168.1.60";
        user = "hermes";
      };
      "krimax-host" = {
        hostname = "192.168.1.96";
        user = "krimax";
      };
      "nepupa-host" = {
        hostname = "192.168.1.85";
        user = "nepupa";
      };
      "vpn1" = {
        hostname = "5.175.188.249";
        user = "root";
        forwardAgent = true;
        serverAliveInterval = 30;
        serverAliveCountMax = 3;
        compression = true;
      };
      "vpn-server" = {
        hostname = "5.175.188.249";
        user = "root";
        forwardAgent = true;
        serverAliveInterval = 30;
        serverAliveCountMax = 3;
        compression = true;
      };
      "vpn-server-ipv6" = {
        hostname = "2a0f:85c1:b73:5d4::a";
        user = "root";
        forwardAgent = true;
        serverAliveInterval = 30;
        serverAliveCountMax = 3;
        compression = true;
      };
      "krimax" = {
        hostname = "192.168.1.96";
        user = "krimax";
      };
      "voidpack" = {
        hostname = "192.168.1.80";
        user = "void";
        extraOptions = {
          PreferredAuthentications = "password,publickey";
          PubkeyAuthentication = "yes";
        };
        serverAliveInterval = 30;
        serverAliveCountMax = 3;
        compression = true;
      };
    };
  };

  # Keep the regular agent as a fallback until Bitwarden's SSH Agent is enabled.
  services.ssh-agent.enable = true;

  programs.bash.profileExtra = lib.mkOrder 1000 preferBitwardenAgent;
  programs.zsh = {
    envExtra = lib.mkOrder 1000 preferBitwardenAgent;
    profileExtra = lib.mkOrder 1000 preferBitwardenAgent;
  };
}
