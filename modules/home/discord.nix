# Discord ships as a self-updating binary. When Discord forces a client upgrade,
# the nix build will fail on hash mismatch — update version + all hashes below.
{ pkgs, lib, ... }:
let
  version = "1.0.154";
  baseUrl = "https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${version}";
  mkModule = name: hash: {
    inherit hash;
    version = 1;
    url = "${baseUrl}/${name}/1/full.distro";
  };
  discord = pkgs.discord.override {
    source = {
      inherit version;
      kind = "distro";
      distro = {
        url = "${baseUrl}/full.distro";
        hash = "sha256-Jbe1c2lQC2ZboXx0lTR5MIuE70YXNstEDRSOa1AaGJo=";
      };
      modules = {
        discord_arborium = mkModule "discord_arborium" "sha256-s4CrlXD5GOzFa5QuvIVbpIVXzTnQo7tToA84Jn2ROdY=";
        discord_cloudsync = mkModule "discord_cloudsync" "sha256-2lfPTEVyLYo5HgC+sSJoXU43KaLUjMy4YvQI6TfURRw=";
        discord_desktop_core = mkModule "discord_desktop_core" "sha256-HFAorKlSZ/Dru4CslYdy0pf/sFYwG4Ir8y4gtozmKW0=";
        discord_dispatch = mkModule "discord_dispatch" "sha256-ZZTfsK9fSK1DGuKVTSt09G9JacaJjJ/VY8kUCP9Iq/8=";
        discord_erlpack = mkModule "discord_erlpack" "sha256-VZcVF6+4Rz3f4kf/fO+UddoHyF5pUisBc19sj55Zz6g=";
        discord_game_utils = mkModule "discord_game_utils" "sha256-kZa3R0JcdhjKTRSOAUwutLRgxf1paeB7wAaZ9Qr7hwk=";
        discord_krisp = mkModule "discord_krisp" "sha256-kpceuaumwlLM4ge3X/cFgpad2Jz780Z0zaLeZxAikX4=";
        discord_modules = mkModule "discord_modules" "sha256-uAU0xzJcXNHbOmb7MRP6Y0uxbpY+o9feJqeIMd6+Xy8=";
        discord_rpc = mkModule "discord_rpc" "sha256-y9qMa45isIIuMamURN8GnJR9IwJcQBVdjZ9y/APyVjw=";
        discord_spellcheck = mkModule "discord_spellcheck" "sha256-rEDql1sShCczi93qFJQRC2SM67JUysjZ99WT3GSGOW8=";
        discord_utils = mkModule "discord_utils" "sha256-8XatkwwkD3Sv49D8jWbBfzXB+ZTdFl/pxis0g34IeqQ=";
        discord_voice = mkModule "discord_voice" "sha256-ahEm4vS8E2iviZg2OkC8wddnPtNdKWLLURHxVnvjA8Y=";
        discord_zstd = mkModule "discord_zstd" "sha256-twZ9vlBJMrqxGI6+jJ9LSrDyVA8R4d4jHMaSVBq+Dnw=";
      };
    };
  };

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
  home.packages = [ discord ];

  # Декларативно размещаем openh264 в asset cache Discord
  home.file.".config/discord/discord_asset_cache/openh264/${openh264Filename}" = {
    source = "${openh264-discord}/${openh264Filename}";
  };
}
