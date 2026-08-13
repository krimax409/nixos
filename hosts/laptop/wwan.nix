{ config, pkgs, ... }:
let
  modemManagerSimSlotDbusPolicy = pkgs.writeTextDir "share/dbus-1/system.d/org.freedesktop.ModemManager1.local-sim-slot.conf" ''
    <!DOCTYPE busconfig PUBLIC
     "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
     "http://www.freedesktop.org/standards/dbus-1.0/busconfig.dtd">
    <busconfig>
      <policy group="networkmanager">
        <allow send_destination="org.freedesktop.ModemManager1"
               send_interface="org.freedesktop.ModemManager1.Modem"
               send_member="SetPrimarySimSlot"/>
      </policy>
    </busconfig>
  '';
in
{
  networking.modemmanager.enable = true;

  environment.systemPackages = with pkgs; [
    libmbim
    libqmi
    mobile-broadband-provider-info
    modem-manager-gui
    usb-modeswitch
  ];

  services.dbus.packages = [ modemManagerSimSlotDbusPolicy ];

  systemd.services = {
    ModemManager.wantedBy = [ "multi-user.target" ];

    wwan-networkmanager-safety = {
      description = "Keep the WWAN NetworkManager profile manual and non-default";
      wantedBy = [ "multi-user.target" ];
      after = [ "NetworkManager.service" ];
      requires = [ "NetworkManager.service" ];
      path = [
        pkgs.networkmanager
        pkgs.coreutils
        pkgs.gnugrep
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if ! nmcli -t -f NAME connection show | grep -Fxq wwan0mbim0; then
          nmcli connection add type gsm ifname "*" con-name wwan0mbim0 apn internet.tele2.ru
        fi

        nmcli connection modify wwan0mbim0 \
          gsm.apn internet.tele2.ru \
          connection.autoconnect no \
          connection.autoconnect-priority -999 \
          ipv4.method auto \
          ipv6.method auto \
          ipv4.never-default yes \
          ipv6.never-default yes \
          ipv4.ignore-auto-routes yes \
          ipv6.ignore-auto-routes yes
      '';
    };

    quectel-physical-sim-slot = {
      description = "Select the physical SIM slot for the internal Quectel modem";
      wantedBy = [ "multi-user.target" ];
      requires = [ "ModemManager.service" ];
      wants = [ "wwan-networkmanager-safety.service" ];
      after = [
        "ModemManager.service"
        "NetworkManager.service"
        "wwan-networkmanager-safety.service"
      ];
      path = [
        config.networking.modemmanager.package
        pkgs.coreutils
        pkgs.gnused
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        modem=""
        for _ in $(seq 1 30); do
          modem="$(mmcli -L 2>/dev/null | sed -n 's#.*Modem/\([0-9]\+\).*#\1#p' | head -n1)"
          [ -n "$modem" ] && break
          sleep 1
        done

        if [ -z "$modem" ]; then
          echo "No ModemManager modem found; leaving WWAN unchanged"
          exit 0
        fi

        slot="$(mmcli -m "$modem" --output-keyvalue 2>/dev/null \
          | sed -n 's/^modem.generic.primary-sim-slot[[:space:]]*:[[:space:]]*//p' \
          | head -n1)"

        if [ "$slot" != "1" ]; then
          echo "Switching WWAN modem $modem from SIM slot ''${slot:-unknown} to physical SIM slot 1"
          mmcli -m "$modem" --set-primary-sim-slot=1 || true
          sleep 8
        fi

        echo "WWAN modem left disconnected; use NetworkManager to connect manually when needed"
      '';
    };
  };
}
