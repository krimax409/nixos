# Discord ships as a self-updating binary. When Discord forces a client upgrade,
# the nix build will fail on hash mismatch — update version + all hashes below.
{ pkgs, lib, ... }:
let
  version = "1.0.151";
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
        hash = "sha256-JAqXFhuMe4zEtAENxxgff4r8Y6KrgHqdeeEKnNMtD6I=";
      };
      modules = {
        discord_arborium = mkModule "discord_arborium" "sha256-fkAcnTwlU99bRfBi/nH1/I7OT6AJ5RtgkHiuQNx08u0=";
        discord_cloudsync = mkModule "discord_cloudsync" "sha256-IkB01+9n6ym1xURoSsmPirK11kyS0GUOujQU24LV3a0=";
        discord_desktop_core = mkModule "discord_desktop_core" "sha256-eot+04aYoRb0w6um1YsGwzXaTBM1IaQwJmzAehkITVE=";
        discord_dispatch = mkModule "discord_dispatch" "sha256-/NYRuR7E9wqHmNxxa97Jj2XY23C7LjzC6SPTgk//7LM=";
        discord_erlpack = mkModule "discord_erlpack" "sha256-84yH4UZkWRoAXM2nL7tamftM71O/wPJznA3tUoRRf+I=";
        discord_game_utils = mkModule "discord_game_utils" "sha256-2oKQlKOUD3Pi00wuE+JKbePmZw5d0Oc6F76GU4/rL0E=";
        discord_krisp = mkModule "discord_krisp" "sha256-4wkbqX5t9/CGiqOi1QPiMDd5NHz7yRcyeKBvhNgHK9Q=";
        discord_modules = mkModule "discord_modules" "sha256-BGBUMO4zMrKaGnxllgjpPyekxeS5xsnICmsSnyJRgUY=";
        discord_rpc = mkModule "discord_rpc" "sha256-yaDuE0OEyNEiHswS9NFvyZE8QsUE4yISJGd6h1bqyZc=";
        discord_spellcheck = mkModule "discord_spellcheck" "sha256-hTcbxupL3UGDeqI35JuBnWSbpwz3taHl3j1rge2Hxgk=";
        discord_utils = mkModule "discord_utils" "sha256-iU2frGSdEctwGB18B0TguO3qgJYyNrQjN0gka683da0=";
        discord_voice = mkModule "discord_voice" "sha256-epFro33WzLfkei7dsN/RMM8hVX8Swv07i2RleGJ/15o=";
        discord_zstd = mkModule "discord_zstd" "sha256-a4aMsI+EN3MRu5jNJgLqkkhtkfV8N8WWaUM48g7W5is=";
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
