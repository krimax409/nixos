{
  lib,
  pkgs,
  host,
  username,
  ...
}:
let
  backupScript = pkgs.writeTextFile {
    name = "hermes-discord-backup.py";
    text = builtins.readFile ./hermes-discord-backup.py;
  };
  hermesHome = "/home/${username}/.hermes";
  ageKeyFile = "/home/${username}/.config/sops/age/keys.txt";
in
lib.mkIf (host == "desktop") {
  sops.secrets.hermes-backup-webhook = {
    sopsFile = ../../secrets/hermes-backup.yaml;
    format = "yaml";
    key = "DISCORD_WEBHOOK";
    owner = username;
    group = "users";
    mode = "0400";
    path = "/run/secrets/hermes-backup-webhook";
  };

  systemd.services.hermes-discord-backup = {
    description = "Encrypted Hermes backup upload to Discord";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.bash ];

    serviceConfig = {
      Type = "oneshot";
      User = username;
      Group = "users";
      ExecStart = "${pkgs.python3}/bin/python ${backupScript}";
      Environment = [
        "HERMES_HOME=${hermesHome}"
        "HERMES_BIN=/home/${username}/.local/bin/hermes"
        "AGE_BIN=${pkgs.age}/bin/age"
        "AGE_KEYGEN_BIN=${pkgs.age}/bin/age-keygen"
        "AGE_KEY_FILE=${ageKeyFile}"
        "WEBHOOK_FILE=/run/secrets/hermes-backup-webhook"
        "STATE_DIR=/var/lib/hermes-discord-backup"
        "PYTHONUNBUFFERED=1"
      ];
      StateDirectory = "hermes-discord-backup";
      UMask = "0077";
      TimeoutStartSec = "30min";
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectSystem = "full";
      ProtectHome = "read-only";
      ReadWritePaths = [
        hermesHome
        "/var/lib/hermes-discord-backup"
      ];
    };
  };

  systemd.timers.hermes-discord-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:17:00";
      Persistent = true;
      RandomizedDelaySec = "15min";
      Unit = "hermes-discord-backup.service";
    };
  };
}
