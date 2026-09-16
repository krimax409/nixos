# Discord ships as a self-updating binary. When Discord forces a client upgrade,
# the nix build will fail on hash mismatch — update version + all hashes below.
{ pkgs, lib, ... }:
let

  # OpenH264 для декодирования H.264 видео в Discord
  # Discord ожидает библиотеку в discord_asset_cache с конкретным именем
  openh264Version = "2.5.1";
  openh264Abi = "7";
  openh264Filename = "libopenh264-${openh264Version}-linux64.${openh264Abi}.so";

  openh264-discord = pkgs.stdenvNoCC.mkDerivation {
    pname = "openh264-discord";
    version = openh264Version;

    src = pkgs.fetchurl {
      # Internet Archive первым — Cisco CDN геоблокирует многие регионы (403)
      # См. https://github.com/cisco/openh264/issues/3886
      urls = [
        "https://web.archive.org/web/20250821053331/https://ciscobinary.openh264.org/${openh264Filename}.bz2"
        "https://ciscobinary.openh264.org/${openh264Filename}.bz2"
      ];
      hash = "sha256-guQ224YGQz4/gjx//zJpxDs7o/ElEKhR73sVa4CtGxE=";
    };

    nativeBuildInputs = [ pkgs.bzip2 ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      bunzip2 -c "$src" > "$out/${openh264Filename}"
      chmod 644 "$out/${openh264Filename}"

      runHook postInstall
    '';

    meta = with lib; {
      description = "Cisco OpenH264 binary for Discord H.264 video decoding";
      homepage = "https://www.openh264.org/";
      # Cisco binary distribution: BSD-2-Clause + AVC/H.264 Patent Portfolio License
      # См. https://www.openh264.org/faq.html
      license = licenses.bsd2;
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  # Equicord/Nixcord is the only Discord client installed here.
  # Keep the normal emoji set: no external Apple Emoji CSS/theme is loaded.
  programs.nixcord = {
    enable = true;
    config = {
      useQuickCss = false;
      plugins = {
        callTimer.enable = true;
        messageLogger = {
          enable = true;
          ignoreBots = false;
        };
        messageLoggerEnhanced = {
          enable = true;
          saveMessages = true;
        };
        translate = {
          enable = true;
          receivedOutput = "ru";
        };
      };
    };
    discord = {
      settings = {
        enableHardwareAcceleration = true;
        openH264Enabled = true;
        openasar.setup = true;
      };
      branches = [ "canary" ];
      commandLineArgs = [ "--proxy-server=http://127.0.0.1:2080" ];
      equicord.enable = true;
      openASAR.enable = true;
      krisp.enable = true;
    };
  };

  # Декларативно размещаем openh264 в asset cache Discord Canary
  home.file.".config/discordcanary/discord_asset_cache/openh264/${openh264Filename}" = {
    source = "${openh264-discord}/${openh264Filename}";
  };
}
