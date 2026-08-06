# Discord ships as a self-updating binary. When Discord forces a client upgrade,
# the nix build will fail on hash mismatch — update version + all hashes below.
{ pkgs, ... }:
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
in
{
  home.packages = [ discord ];
}
