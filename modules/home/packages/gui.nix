{ inputs, osConfig ? { }, pkgs, ... }:
let
  zcode = pkgs.stdenv.mkDerivation rec {
    pname = "zcode";
    version = "3.11.2";

    src = pkgs.fetchurl {
      url = "https://cdn-zcode.z.ai/zcode/electron/releases/${version}/linux-x64/ZCode-${version}-linux-x64.deb";
      hash = "sha256-fRO4OGMTAs9h4bgEDLZ/NJ7CNWZ5WJfxdGQyxcXXfVs=";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      dpkg
      makeWrapper
      wrapGAppsHook3
    ];

    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      libappindicator-gtk3
      libdrm
      libgbm
      libnotify
      libsecret
      libuuid
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
      libxkbcommon
      libxscrnsaver
      libxtst
      nspr
      nss
      pango
      stdenv.cc.cc
      wayland
      xdg-utils
    ];

    strictDeps = true;
    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --extract "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/opt/ZCode" "$out/bin" "$out/share/applications"
      cp -a opt/ZCode/. "$out/opt/ZCode/"

      makeWrapper "$out/opt/ZCode/zcode" "$out/bin/zcode" \
        --prefix PATH : "${
          pkgs.lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.findutils
            pkgs.git
            pkgs.gnugrep
            pkgs.openssh
            pkgs.xdg-utils
          ]
        }"

      sed "s#^Exec=/opt/ZCode/zcode %U\$#Exec=$out/bin/zcode %U#" \
        usr/share/applications/zcode.desktop > "$out/share/applications/zcode.desktop"
      cp -a usr/share/icons "$out/share/"

      runHook postInstall
    '';

    meta = {
      description = "ZCode desktop AI coding assistant";
      homepage = "https://zcode.z.ai";
      license = pkgs.lib.licenses.unfree;
      mainProgram = "zcode";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    };
  };

  bitwardenDesktopLauncher = pkgs.writeShellScriptBin "bitwarden-desktop-launcher" ''
    if [ -t 1 ] && [ -t 2 ]; then
      exec ${pkgs.lib.getExe pkgs.bitwarden-desktop} "$@"
    fi

    # Graphical launchers may close inherited pipes after spawning Electron.
    # Keep the app logger active while preventing an uncaught stdout EPIPE.
    exec ${pkgs.lib.getExe pkgs.bitwarden-desktop} "$@" >/dev/null 2>&1
  '';

  easycliproxyapi = pkgs.callPackage ../../../pkgs/easycliproxyapi.nix { };

  raspberryDesktop = pkgs.callPackage ../../../pkgs/raspberry-desktop.nix { inherit inputs; };

  orcaIde = pkgs.appimageTools.wrapAppImage rec {
    pname = "orca-ide";
    version = "1.4.274";
    src = appimageContents;
    passthru = { inherit appimageContents; };

    appimageContents = pkgs.appimageTools.extract {
      inherit pname version;
      src = pkgs.fetchurl {
        url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
        hash = "sha256-THnB/cXz3UV5taQak1pZQD11HGAfKVzah4vAbma30mA=";
      };
      postExtract = pkgs.lib.optionalString ((osConfig.networking.hostName or null) == "pc") ''
        install -m444 ${./orca-relay-proxy.cjs} "$out/resources/orca-relay-proxy.cjs"
        printf '%s\n' 'require("./orca-relay-proxy.cjs")({ nativeWebSocket: true })' > "$out/resources/orca-relay-worker-proxy.cjs"
        ${pkgs.python3}/bin/python3 ${./orca-relay-proxy.py} "$out/resources/app.asar"
      '';
    };

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/orca-ide.desktop -t $out/share/applications/
      install -Dm444 ${appimageContents}/orca-ide.png \
        -t $out/share/icons/hicolor/512x512/apps/
      substituteInPlace $out/share/applications/orca-ide.desktop \
        --replace-fail 'Exec=AppRun' "Exec=$out/bin/orca-ide"

      # On niri Chromium cannot detect a desktop environment, so OSCrypt picks
      # the BASIC_TEXT backend and safeStorage.isEncryptionAvailable() is
      # false. Orca then keeps the cloud account session memory-only and every
      # restart logs the user out. Force libsecret (KeePassXC Secret Service).
      # KeePassXC does not ship a D-Bus activation file, so briefly wait for
      # it to claim org.freedesktop.secrets before launching.
      mv $out/bin/orca-ide $out/bin/.orca-ide-wrapped
      cat > $out/bin/orca-ide <<'EOF'
#!${pkgs.runtimeShell}
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  ${pkgs.systemd}/bin/busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.DBus.Properties Get ss org.freedesktop.Secret.Service Collections >/dev/null 2>&1 && break
  sleep 1
done
exec "$(dirname "$(readlink -f "$0")")/.orca-ide-wrapped" --password-store=gnome-libsecret "$@"
EOF
      chmod +x $out/bin/orca-ide
    '';

    meta = {
      description = "Agent development environment for parallel coding workflows";
      homepage = "https://www.onorca.dev/";
      license = pkgs.lib.licenses.mit;
      mainProgram = "orca-ide";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    };
  };

  codexDesktop = pkgs.buildFHSEnv {
    name = "codex-desktop";
    executableName = "chatgpt";
    targetPkgs =
      pkgs: with pkgs; [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        dbus
        expat
        gdk-pixbuf
        git
        glib
        gtk3
        libdrm
        libgbm
        libnotify
        libsecret
        libusb1
        libX11
        libXcomposite
        libXcursor
        libXdamage
        libXext
        libXfixes
        libXrandr
        libxcb
        libxkbcommon
        libxshmfence
        libxtst
        mesa
        nspr
        nss
        openssl
        pango
        stdenv.cc.cc
        systemd
        tpm2-tss
        vulkan-loader
        wayland
        xdg-utils
      ];
    runScript = pkgs.writeShellScript "codex-desktop-launch" ''
      root="''${XDG_DATA_HOME:-$HOME/.local/share}/codex"
      app="$root/current/usr/lib/chatgpt/ChatGPT"
      if [ ! -x "$app" ]; then
        echo "ChatGPT is not installed. Run codex-update first." >&2
        exit 1
      fi
      exec "$app" "$@"
    '';
    meta = {
      description = "ChatGPT desktop application with Codex for Linux (manual updates)";
      homepage = "https://developers.openai.com/codex/app";
      license = pkgs.lib.licenses.unfree;
      mainProgram = "chatgpt";
      platforms = [ "x86_64-linux" ];
    };
  };

  codexUpdate = pkgs.writeShellScriptBin "codex-update" ''
    export PATH="${
      pkgs.lib.makeBinPath (
        with pkgs;
        [
          curl
          dpkg
          perl
          coreutils
          util-linux
        ]
      )
    }:$PATH"
    export CODEX_LAUNCHER="${codexDesktop}/bin/chatgpt"
    ${builtins.readFile ../scripts/scripts/codex-update.sh}
  '';
in
{
  home.packages = with pkgs; [
    ## AI coding
    codexDesktop
    codexUpdate
    easycliproxyapi
    orcaIde
    opencode-desktop
    zcode

    ## Database
    inputs.dbx.packages.${pkgs.stdenv.hostPlatform.system}.dbx-desktop

    ## Multimedia
    audacity
    gimp
    obs-studio
    pavucontrol
    raspberryDesktop
    soundwireserver
    video-trimmer

    ## Communication
    telegram-desktop

    ## Office
    libreoffice

    ## Password manager
    bitwarden-desktop

    ## Utility
    gnome-disk-utility
    zenity

    ## Level editor
    ldtk
    tiled
  ];

  home.file.".local/bin/orca-ide" = {
    # Pin the stale app-installed CLI symlink to the packaged script; it execs
    # the extracted Electron with ELECTRON_RUN_AS_NODE (nix-ld covers the ELF).
    # force replaces the foreign symlink; a regular file still goes to .backup.
    source = "${orcaIde.appimageContents}/resources/bin/orca-ide";
    force = true;
  };

  systemd.user.services.easycliproxyapi = {
    Unit = {
      Description = "EasyCLIProxyAPI desktop console";
      # WebKitGTK mis-reads monitor scale when started before niri finishes
      # configuring outputs, leaving the webview rendered at ~20% zoom.
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Environment = [
        "GSETTINGS_SCHEMA_DIR=${pkgs.glib.getSchemaPath pkgs.gsettings-desktop-schemas}"
      ];
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = "${easycliproxyapi}/bin/easycliproxyapi";
      # Self-update helper is a plain child in the same cgroup. With the
      # default ExitType=main the unit deactivates as soon as the GUI exits 0
      # (after writing update-helper-started.ack), and KillMode=control-group
      # then kills the helper before it can write update-started.ack.
      ExitType = "cgroup";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.desktopEntries.bitwarden = {
    name = "Bitwarden";
    genericName = "Password Manager";
    exec = "${bitwardenDesktopLauncher}/bin/bitwarden-desktop-launcher %U";
    icon = "bitwarden";
    terminal = false;
    categories = [ "Utility" ];
    mimeType = [ "x-scheme-handler/bitwarden" ];
  };
}
