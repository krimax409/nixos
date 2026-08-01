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
  };

  services.ssh-agent.enable = true;
}
