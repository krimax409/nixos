{
  lib,
  stdenv,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  yarn,
  electron_41-bin,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  inputs,
}:

let
  electron = electron_41-bin;
in
stdenv.mkDerivation {
  pname = "raspberry-desktop";
  version = "2.1.3";

  src = inputs.raspberryDesktop;

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${inputs.raspberryDesktop}/yarn.lock";
    hash = "sha256-LmLOs4zm/hvP0+v8RFyvVsxHf5nNJLPMsepkWejpLvA=";
  };

  nativeBuildInputs = [
    nodejs
    yarn
    yarnConfigHook
    yarnBuildHook
    makeWrapper
    copyDesktopItems
  ];

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  dontWrapGApps = true;

  postBuild = ''
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist
    yarn --offline run electron-builder --dir \
      -c.electronDist=electron-dist \
      -c.electronVersion=${electron.version}
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/raspberry
    cp -a dist/linux-unpacked/resources $out/share/raspberry/
    install -Dm644 icons/256x256.png \
      $out/share/icons/hicolor/256x256/apps/raspberry.png

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper ${electron}/bin/electron $out/bin/raspberry \
      --set ELECTRON_FORCE_IS_PACKAGED 1 \
      --set ELECTRON_IS_DEV 0 \
      --add-flags "$out/share/raspberry/resources/app"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "raspberry";
      desktopName = "Raspberry";
      exec = "raspberry %U";
      icon = "raspberry";
      terminal = false;
      categories = [ "AudioVideo" ];
      mimeTypes = [ "x-scheme-handler/reyohoho" ];
    })
  ];

  meta = {
    description = "Desktop torrent streaming application";
    homepage = "https://github.com/mazda1337/raspberry-desktop";
    license = lib.licenses.cc0;
    mainProgram = "raspberry";
    platforms = [ "x86_64-linux" ];
  };
}
