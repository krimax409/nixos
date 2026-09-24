{
  lib,
  stdenv,
  autoPatchelfHook,
  coreutils,
  fetchurl,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libX11,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXinerama,
  libXrandr,
  libxcb,
  libxkbcommon,
  libxscrnsaver,
  libxtst,
  libsoup_3,
  pango,
  webkitgtk_4_1,
  wayland,
}:

stdenv.mkDerivation rec {
  pname = "easycliproxyapi";
  version = "0.3.0";

  src = fetchurl {
    url = "https://github.com/router-for-me/EasyCLIProxyAPI/releases/download/v${version}/EasyCLIProxyAPI-v${version}-Linux-amd64.tar.gz";
    hash = "sha256-xlEhYYLmNlIyWGTyNaDX6NJzCq2S+gqhNCQOVY3kcBI=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
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
    libX11
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXinerama
    libXrandr
    libxcb
    libxkbcommon
    libxscrnsaver
    libxtst
    libsoup_3
    pango
    webkitgtk_4_1
    wayland
  ];

  sourceRoot = "EasyCLIProxyAPI-v${version}-Linux-amd64";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 EasyCLIProxyAPI $out/lib/easycliproxyapi/EasyCLIProxyAPI
    install -Dm644 core-version.txt $out/lib/easycliproxyapi/core-version.txt
    install -Dm644 portable-app.json $out/lib/easycliproxyapi/portable-app.json
    mkdir -p $out/lib/easycliproxyapi/cpa-core
    cp -a cpa-core/. $out/lib/easycliproxyapi/cpa-core/

    install -Dm755 /dev/stdin $out/bin/easycliproxyapi <<'EOF'
    #!${stdenv.shell}
    set -eu

    data_dir="''${XDG_DATA_HOME:-''${HOME}/.local/share}/easycliproxyapi"
    payload_dir="''${data_dir}/payload"

    if [ ! -x "''${payload_dir}/EasyCLIProxyAPI" ]; then
      ${coreutils}/bin/rm -rf "''${payload_dir}.new"
      ${coreutils}/bin/mkdir -p "''${payload_dir}.new/cpa-core"
      ${coreutils}/bin/cp "${placeholder "out"}/lib/easycliproxyapi/EasyCLIProxyAPI" "''${payload_dir}.new/EasyCLIProxyAPI"
      ${coreutils}/bin/cp "${placeholder "out"}/lib/easycliproxyapi/core-version.txt" "''${payload_dir}.new/core-version.txt"
      ${coreutils}/bin/cp "${placeholder "out"}/lib/easycliproxyapi/portable-app.json" "''${payload_dir}.new/portable-app.json"
      ${coreutils}/bin/cp -a "${placeholder "out"}/lib/easycliproxyapi/cpa-core/." "''${payload_dir}.new/cpa-core/"
      ${coreutils}/bin/chmod -R u+rwX "''${payload_dir}.new"
      ${coreutils}/bin/mkdir -p "''${data_dir}"
      ${coreutils}/bin/rm -rf "''${payload_dir}"
      ${coreutils}/bin/mv "''${payload_dir}.new" "''${payload_dir}"
    fi

    export GTK_CSD=0
    exec "''${payload_dir}/EasyCLIProxyAPI" "''$@"
    EOF

    install -Dm644 /dev/stdin $out/share/applications/easycliproxyapi.desktop <<EOF
    [Desktop Entry]
    Name=EasyCLIProxyAPI
    Comment=Desktop GUI for CLIProxyAPI
    Exec=$out/bin/easycliproxyapi
    Terminal=false
    Type=Application
    Categories=Development;Network;
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Desktop GUI for CLIProxyAPI";
    homepage = "https://github.com/router-for-me/EasyCLIProxyAPI";
    license = lib.licenses.mit;
    mainProgram = "easycliproxyapi";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
