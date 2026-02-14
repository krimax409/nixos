{
  pkgs,
  inputs,
  username,
  host,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager = {
    backupFileExtension = "backup";
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host; };
    users.${username} = {
      imports = [ ./../home ];
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "24.05";
      programs.home-manager.enable = true;

      # Автоматическая очистка старых backup файлов перед активацией
      home.activation.cleanupBackups = {
        before = [ "checkLinkTargets" ];
        after = [ ];
        data = ''
          echo "Cleaning up old backup files..."
          find /home/${username} -maxdepth 1 -type f \( -name "*.backup" -o -name "*.hm-bak-*" \) -delete 2>/dev/null || true
        '';
      };
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  nix.settings.allowed-users = [ "${username}" ];
}
