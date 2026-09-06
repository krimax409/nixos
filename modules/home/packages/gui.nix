{ pkgs, ... }:
let
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
    opencode-desktop

    ## Multimedia
    audacity
    gimp
    obs-studio
    pavucontrol
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
}
