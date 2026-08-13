{ inputs, pkgs, ... }:
let
  grokBuildVersion = "1.0.3";
  grokBuildStable = pkgs.grok-build.overrideAttrs (old: {
    pname = "grok-build-stable";
    version = grokBuildVersion;
    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/grok-build-public-artifacts/cli/grok-${grokBuildVersion}-linux-x86_64";
      hash = "sha256-Kn1G3qP77QZ+QHIli4NdQB4BfWhI3JliefD7PWaKCWE=";
    };
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/grok-stable"
      ln -s grok-stable "$out/bin/agent-stable"
      runHook postInstall
    '';
    doInstallCheck = false;
    meta = old.meta // {
      mainProgram = "grok-stable";
    };
  });
  grokBuild = pkgs.rustPlatform.buildRustPackage {
    pname = "grok-build-main";
    version = "0-unstable-2026-08-13";
    src = pkgs.fetchurl {
      url = "https://github.com/xai-org/grok-build/archive/e5fd4816d43260c15ba785f103990c1ed6cea230.tar.gz";
      hash = "sha256-U9m+vWfIjh0v0syPSMtL3NUvbgcBfYeNiXEXI5IyElo=";
    };
    sourceRoot = "grok-build-e5fd4816d43260c15ba785f103990c1ed6cea230";
    cargoHash = "sha256-hbVzI9NUvIahfWHdzRLvJLvis7/EK0VQTb0seQcIqb0=";
    cargoBuildFlags = [ "-p" "xai-grok-pager-bin" ];
    postPatch = ''
      # A6API's GPT-5.6 Sol emits function.name = "" on argument-only
      # chunks. Treat that as omitted, otherwise it erases the first name.
      substituteInPlace crates/codegen/xai-grok-sampler/src/stream/chat_completions.rs \
        --replace-fail \
          'if let Some(name) = func.name {' \
          'if let Some(name) = func.name.filter(|name| !name.is_empty()) {'
    '';
    nativeBuildInputs = with pkgs; [ pkg-config protobuf ];
    buildInputs = with pkgs; [ openssl ];
    PROTOC = "${pkgs.protobuf}/bin/protoc";
    GROK_TOOLS_BUNDLE_RG_PATH = "${pkgs.ripgrep}/bin/rg";
    GROK_SHELL_BUNDLE_RG_PATH = "${pkgs.ripgrep}/bin/rg";
    doCheck = false;
    postInstall = ''
      mv "$out/bin/xai-grok-pager" "$out/bin/grok"
      ln -s grok "$out/bin/agent"
    '';
    meta = {
      description = "xAI coding agent built from the latest grok-build source";
      homepage = "https://github.com/xai-org/grok-build";
      license = pkgs.lib.licenses.unfreeRedistributable;
      mainProgram = "grok";
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  home.packages = with pkgs; [
    ## Better core utils
    duf # disk information
    eza # ls replacement
    fd # find replacement
    gping # ping with a graph
    gtrash # rm replacement, put deleted files in system trash
    hexyl # hex viewer
    man-pages # extra man pages
    ncdu # disk space
    ripgrep # grep replacement

    ## Tools / useful cli
    asciinema
    asciinema-agg
    binsider
    bitwise # cli tool for bit / hex manipulation
    broot # tree files view
    caligula # User-friendly, lightweight TUI for disk imaging
    grokBuild # xAI coding agent from grok-build main (commands: grok, agent)
    grokBuildStable # pinned stable fallback (commands: grok-stable, agent-stable)
    hyperfine # benchmarking tool
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    pastel # cli to manipulate colors
    swappy # snapshot editing tool
    tdf # cli pdf viewer
    tmux # terminal multiplexer (fractal тянет свой через обёртку)
    tokei # project line counter
    woomer # screen zoom for wayland (SUPER + =)
    yt-dlp-light

    ## TUI
    toipe # typing test in the terminal
    tomato-c # TUI pomodoro timer
    ttyper # cli typing test

    ## Monitoring / fetch
    htop
    nitch # system fetch util
    onefetch # fetch utility for git repo
    wavemon # monitoring for wireless network devices

    ## Fun / screensaver
    asciiquarium-transparent
    cmatrix
    countryfetch
    lavat
    pipes # command: pipes.sh
    sl
    tty-clock

    ## Multimedia
    ani-cli
    imv
    lowfi
    mpv

    ## Utilities
    entr # perform action when file change
    ffmpeg
    file # Show file information
    jq # JSON processor
    killall
    libnotify
    mimeo
    openssl
    pamixer # pulseaudio command line mixer
    playerctl # controller for media players
    unzip
    wl-clipboard # clipboard utils for wayland (wl-copy, wl-paste)
    xdg-utils

    winetricks
    wineWow64Packages.waylandFull
  ];
}
