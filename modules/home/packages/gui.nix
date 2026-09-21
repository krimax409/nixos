{ inputs, pkgs, ... }:
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

  orcaIde = pkgs.appimageTools.wrapType2 rec {
    pname = "orca-ide";
    version = "1.4.200";

    src = pkgs.fetchurl {
      url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
      hash = "sha256-yC2d31MkMeDaUexdGJmg4xWqu453/ORezOf61HM/yWo=";
    };

    appimageContents = pkgs.appimageTools.extract { inherit pname version src; };

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/orca-ide.desktop -t $out/share/applications/
      install -Dm444 ${appimageContents}/orca-ide.png \
        -t $out/share/icons/hicolor/512x512/apps/
      substituteInPlace $out/share/applications/orca-ide.desktop \
        --replace-fail 'Exec=AppRun' "Exec=$out/bin/orca-ide"
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

  codexDesktop = pkgs.stdenv.mkDerivation rec {
    pname = "codex-desktop";
    version = "26.901.51231";

    src = pkgs.fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
      hash = "sha256-YlgBiNh8PTqTadq3xztCqKMlGNTfii1brmRm3erFwF4=";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      dpkg
      makeWrapper
      perl
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
      nspr
      nss
      pango
      stdenv.cc.cc
      systemd
      vulkan-loader
      wayland
    ];

    strictDeps = true;
    dontConfigure = true;
    dontBuild = true;
    autoPatchelfIgnoreMissingDeps = [
      "libQt5Core.so.5"
      "libQt5Gui.so.5"
      "libQt5Widgets.so.5"
      "libQt6Core.so.6"
      "libQt6Gui.so.6"
      "libQt6Widgets.so.6"
      "libc.musl-x86_64.so.1"
    ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --extract "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib/chatgpt" "$out/bin"
      cp -a usr/lib/chatgpt/. "$out/lib/chatgpt/"

      makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
        --prefix PATH : "${
          pkgs.lib.makeBinPath [
            pkgs.git
            pkgs.glib
            pkgs.xdg-utils
          ]
        }"

      install -Dm644 usr/share/applications/chatgpt.desktop \
        "$out/share/applications/chatgpt.desktop"
      install -Dm644 usr/share/pixmaps/chatgpt.png \
        "$out/share/pixmaps/chatgpt.png"

      # Desktop 26.901.x aborts in its native Git-worker callback on Linux.
      # Keep Git commands available, but skip the crashing live repository
      # watcher until the upstream worker is fixed.
      ${pkgs.perl}/bin/perl -0e '
        my $path = shift @ARGV;
        open my $in, "<", $path or die "cannot read $path: $!";
        binmode $in;
        local $/;
        my $data = <$in>;
        close $in;

        for my $old (
          q#this.ensureWatching(t,o)#,
          q#this.ensureWatching(r,o,i.signal)#,
          q#this.ensureWatching({commonDir:r.commonDir,root:r.root},t)#
        ) {
          my $new = "Promise.resolve()" . (" " x (length($old) - length("Promise.resolve()")));
          my $first = index($data, $old);
          die "Git-worker patch target not found: $old\n" if $first < 0;
          die "Git-worker patch target is ambiguous: $old\n" if index($data, $old, $first + length($old)) >= 0;
          substr($data, $first, length($old), $new);
        }

        open my $out, ">", $path or die "cannot write $path: $!";
        binmode $out;
        print {$out} $data;
        close $out;
      ' "$out/lib/chatgpt/resources/app.asar"

      runHook postInstall
    '';

    meta = {
      description = "ChatGPT desktop application with Codex for Linux";
      homepage = "https://developers.openai.com/codex/app";
      license = pkgs.lib.licenses.unfree;
      mainProgram = "chatgpt";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    };
  };
in
{
  home.packages = with pkgs; [
    ## AI coding
    codexDesktop
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

  systemd.user.services.easycliproxyapi = {
    Unit = {
      Description = "EasyCLIProxyAPI desktop console";
      # WebKitGTK mis-reads monitor scale when started before niri finishes
      # configuring outputs, leaving the webview rendered at ~20% zoom.
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = "${easycliproxyapi}/bin/easycliproxyapi";
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
