{ inputs, pkgs, ... }:
let
  mkGrokBinary =
    {
      version,
      hash,
      suffix,
    }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "grok-build-${suffix}";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://storage.googleapis.com/grok-build-public-artifacts/cli/grok-${version}-linux-x86_64";
        inherit hash;
      };
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        install -Dm755 "$src" "$out/bin/grok-${suffix}"
        ln -s grok-${suffix} "$out/bin/agent-${suffix}"
        runHook postInstall
      '';
      doInstallCheck = true;
      installCheckPhase = ''
        "$out/bin/grok-${suffix}" --version | grep -F "grok ${version}"
      '';
      meta = {
        description = "Pinned xAI Grok CLI ${version} (${suffix})";
        homepage = "https://github.com/xai-org/grok-build";
        license = pkgs.lib.licenses.unfreeRedistributable;
        mainProgram = "grok-${suffix}";
        platforms = [ "x86_64-linux" ];
      };
    };
  grokBuildStable = mkGrokBinary {
    version = "1.0.8";
    hash = "sha256-d0V4bAOIbryMxT6x5/gwiu+5Yy9fvrzDM3iDTc16wFA=";
    suffix = "stable";
  };
  grokBuildStablePrevious105 = mkGrokBinary {
    version = "1.0.5";
    hash = "sha256-m6h0ROGBno9hBK279GdqhwwgQ4CqXD4cOKkmxOpncjg=";
    suffix = "stable-previous-1-0-5";
  };
  grokBuildStablePrevious = mkGrokBinary {
    version = "1.0.3";
    hash = "sha256-Kn1G3qP77QZ+QHIli4NdQB4BfWhI3JliefD7PWaKCWE=";
    suffix = "stable-previous";
  };
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
  grokBuildPrevious = pkgs.rustPlatform.buildRustPackage {
    pname = "grok-build-main-previous";
    version = "1.0.3-source-e5fd4816";
    src = pkgs.fetchurl {
      url = "https://github.com/xai-org/grok-build/archive/e5fd4816d43260c15ba785f103990c1ed6cea230.tar.gz";
      hash = "sha256-U9m+vWfIjh0v0syPSMtL3NUvbgcBfYeNiXEXI5IyElo=";
    };
    sourceRoot = "grok-build-e5fd4816d43260c15ba785f103990c1ed6cea230";
    cargoHash = "sha256-hbVzI9NUvIahfWHdzRLvJLvis7/EK0VQTb0seQcIqb0=";
    cargoBuildFlags = [
      "-p"
      "xai-grok-pager-bin"
    ];
    postPatch = ''
      # A6API's GPT-5.6 Sol emits function.name = "" on argument-only
      # chunks. Treat that as omitted, otherwise it erases the first name.
      substituteInPlace crates/codegen/xai-grok-sampler/src/stream/chat_completions.rs \
        --replace-fail \
          'if let Some(name) = func.name {' \
          'if let Some(name) = func.name.filter(|name| !name.is_empty()) {'
    '';
    nativeBuildInputs = with pkgs; [
      pkg-config
      protobuf
    ];
    buildInputs = with pkgs; [ openssl ];
    PROTOC = "${pkgs.protobuf}/bin/protoc";
    GROK_TOOLS_BUNDLE_RG_PATH = "${pkgs.ripgrep}/bin/rg";
    GROK_SHELL_BUNDLE_RG_PATH = "${pkgs.ripgrep}/bin/rg";
    doCheck = false;
    postInstall = ''
      mv "$out/bin/xai-grok-pager" "$out/bin/grok-main-previous"
      ln -s grok-main-previous "$out/bin/agent-main-previous"
    '';
    meta = {
      description = "Pinned previous xAI Grok source build for rollback";
      homepage = "https://github.com/xai-org/grok-build";
      license = pkgs.lib.licenses.unfreeRedistributable;
      mainProgram = "grok-main-previous";
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
    grokBuildPrevious # exact previous source build (grok-main-previous, agent-main-previous)
    grokBuildStable # current stable binary (grok-stable, agent-stable)
    grokBuildStablePrevious105 # previous stable 1.0.5 rollback
    grokBuildStablePrevious # previous stable binary (grok-stable-previous, agent-stable-previous)
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
