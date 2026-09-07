{ inputs, pkgs, ... }:
let
  # Official xAI binary from the pinned nixpkgs master input; no source build.
  grokBuild = (import inputs.codex-nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  }).grok-build;

  secretspecMain = pkgs.rustPlatform.buildRustPackage {
    pname = "secretspec-main";
    version = "0.19.1-main-98da929";
    src = pkgs.fetchFromGitHub {
      owner = "cachix";
      repo = "secretspec";
      rev = "98da9292b31817c3a4c696d0112eacd13905651e";
      hash = "sha256-mD6sLKXLqJazvIj9zhhfKYhzb6zHL5wtL+5s7TgcHj4=";
    };
    cargoHash = "sha256-BP9u86MyhIUxyYlOjzJHRNNRabAwbCT0RoPTYrmVVQU=";
    cargoBuildFlags = [ "-p" "secretspec" ];
    buildFeatures = [ "cli" "infisical" ];
    doCheck = false;
    meta = {
      description = "SecretSpec built from upstream main";
      homepage = "https://github.com/cachix/secretspec";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "secretspec";
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
    sops # encrypted secrets
    age # age encryption CLI
    secretspecMain # upstream main build for Infisical verification

    ## Tools / useful cli
    asciinema
    asciinema-agg
    binsider
    bitwise # cli tool for bit / hex manipulation
    broot # tree files view
    caligula # User-friendly, lightweight TUI for disk imaging
    grokBuild
    opencode # OpenCode coding agent CLI
    hyperfine # benchmarking tool
    llmfit # match LLM models to available hardware
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
