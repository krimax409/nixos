# KeePassXC as the freedesktop Secret Service provider.
# Replaces gnome-keyring (see modules/core/services.nix — disabled there).
# The database is unlocked by a keyfile (~/.config/keepassxc/keyfile), so no
# password prompt is needed on autologin. If the keyfile is lost, the DB is
# unrecoverable — it lives next to the DB on purpose; this host treats
# keyfile-as-secret as acceptable (same as an unlocked keyring).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  configDir = "${config.xdg.configHome}/keepassxc";
  dbPath = "${configDir}/Passwords.kdbx";
  keyfilePath = "${configDir}/keyfile";
in
{
  home.packages = [ pkgs.keepassxc ];

  xdg.configFile."keepassxc/keepassxc.ini" = {
    text = lib.generators.toINI { } {
      GUI = {
        MinimizeOnStartup = true;
        # niri has no StatusNotifier tray host; KeePassXC's tray icon crashes
        # there, so the window stays a normal (minimized) window.
        MinimizeToTray = false;
        ShowTrayIcon = false;
        MinimizeOnClose = false;
      };
      General = {
        DropToBackgroundOnCopy = false;
      };
      # This instance is a headless Secret Service provider: auto-locking the
      # DB would deadlock every client the same way gnome-keyring did.
      Security = {
        LockDatabaseIdle = false;
        LockDatabaseMinimize = false;
        LockDatabaseScreenLock = false;
        LockDatabaseOnUserSwitch = false;
      };
      FdoSecrets = {
        Enabled = true;
        ShowNotification = false;
        ConfirmDeleteItem = false;
        ConfirmAccessItem = false;
        UnlockBeforeSearch = false;
      };
      Browser = {
        Enabled = false;
      };
      SSHAgent = {
        Enabled = false;
      };
      PasswordGenerator = {
        AdditionalChars = "";
        ExcludedChars = "";
      };
    };
    # keepassxc rewrites this file at runtime; keep a real file, not a symlink.
    force = true;
  };

  # Spawned by niri at session start (see configs/niri/common.kdl).
  home.file.".local/bin/keepassxc-unlocked" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      mkdir -p ${lib.escapeShellArg configDir}
      if [ ! -f ${lib.escapeShellArg keyfilePath} ]; then
        ${pkgs.openssl}/bin/openssl rand -base64 32 > ${lib.escapeShellArg keyfilePath}
        chmod 600 ${lib.escapeShellArg keyfilePath}
      fi
      if [ ! -f ${lib.escapeShellArg dbPath} ]; then
        tmp=$(mktemp -d)
        ${pkgs.keepassxc}/bin/keepassxc-cli db-create \
          --set-key-file ${lib.escapeShellArg keyfilePath} \
          "$tmp/base.kdbx" < /dev/null
        ${pkgs.keepassxc}/bin/keepassxc-cli export \
          --no-password -k ${lib.escapeShellArg keyfilePath} -f xml \
          "$tmp/base.kdbx" > "$tmp/base.xml"
        # Expose the root group as the Secret Service collection — the setting
        # is stored in DB custom data (FDO_SECRETS_EXPOSED_GROUP), writable
        # only via the XML export/import round-trip.
        ${pkgs.python3}/bin/python3 - "$tmp/base.xml" <<'PYEOF'
      import re, base64, uuid, sys
      x = open(sys.argv[1]).read()
      m = re.search(r"<Group>\s*<UUID>([^<]+)</UUID>", x)
      u = str(uuid.UUID(bytes=base64.b64decode(m.group(1))))
      item = (
          "<Item><Key>FDO_SECRETS_EXPOSED_GROUP</Key>"
          f"<Value>{{{u}}}</Value>"
          "<LastModificationTime>2026-09-26T14:00:00Z</LastModificationTime>"
          "</Item>"
      )
      x = x.replace("</CustomData>", item + "\n\t\t</CustomData>", 1)
      open(sys.argv[1], "w").write(x)
      PYEOF
        ${pkgs.keepassxc}/bin/keepassxc-cli import \
          --set-key-file ${lib.escapeShellArg keyfilePath} \
          "$tmp/base.xml" ${lib.escapeShellArg dbPath} < /dev/null
        rm -rf "$tmp"
      fi
      # NOTE: KeePassXC crashes deterministically (SIGSEGV in
      # MainWindow::bringToFront -> QWidgetPrivate::showChildren) when it
      # auto-unlocks a DB passed on the command line while started detached —
      # upstream bug https://github.com/keepassxreboot/keepassxc/issues/13521
      # (dup of #9799). Workaround verified on this host: start with no DB
      # (Welcome screen is fine minimized), then open the DB over its own
      # D-Bus API, which routes through the already-shown window.
      if ! ${pkgs.systemd}/bin/busctl --user list 2>/dev/null | \
           grep -q org.keepassxc.KeePassXC.MainWindow; then
        ${pkgs.keepassxc}/bin/keepassxc --minimized &
        for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
          sleep 1
          ${pkgs.systemd}/bin/busctl --user list 2>/dev/null | \
            grep -q org.keepassxc.KeePassXC.MainWindow && break
        done
      fi
      ${pkgs.systemd}/bin/busctl --user call \
        org.keepassxc.KeePassXC.MainWindow /keepassxc \
        org.keepassxc.KeePassXC.MainWindow openDatabase sss \
        ${lib.escapeShellArg dbPath} "" ${lib.escapeShellArg keyfilePath}
    '';
  };

}
