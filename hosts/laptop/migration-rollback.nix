{ pkgs, ... }:
let
  previousSystem = "/nix/store/sxxv6n4dk6kr58y5vw9g9k8bsmrdacdq-nixos-system-nixos-26.11.20260616.567a49d";
  confirmationMarker = "/home/krim/.shared-config-migration-confirmed";
  rescue = pkgs.writeShellScript "laptop-migration-rescue" ''
    if [ ! -e ${confirmationMarker} ]; then
      exec ${previousSystem}/bin/switch-to-configuration test
    fi
  '';
in
{
  systemd.services.laptop-migration-rollback = {
    description = "Start the previous NixOS generation unless migration is confirmed";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = rescue;
    };
  };

  systemd.timers.laptop-migration-rollback = {
    description = "Rollback unconfirmed laptop migration after five minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnActiveSec = "5m";
      Unit = "laptop-migration-rollback.service";
    };
  };
}
