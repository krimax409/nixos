{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    ## IDE
    zed-editor

    ## Lsp
    nixd # nix

    ## formating
    shfmt
    treefmt
    nixfmt

    ## C / C++
    gcc
    gdb
    gef
    cmake
    gnumake
    valgrind
    llvmPackages_20.clang-tools

    ## Go
    go
    gopls
    delve
    golangci-lint
    gofumpt

    ## Rust
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt
    cargo-watch
    cargo-nextest

    ## JavaScript / TypeScript
    nodejs # node, npm, npx
    pnpm
    bun
    typescript # tsc
    typescript-language-server
    vscode-langservers-extracted # eslint, html, css, json LSP
    biome # linter + formatter
    prettier
    nodemon

    # nub: Rust toolkit over stock node (runner, pm, watcher, version manager).
    # Not in nixpkgs; pinned as a flake input. Provides nub and nubx.
    inputs.nub.packages.${pkgs.stdenv.hostPlatform.system}.default

    ## Native deps (used by Rust/Go CGO)
    # openssl comes from cli.nix; linking needs openssl.dev from a project devShell
    pkg-config

    ## Python
    python3
    python312Packages.ipython
    uv # Python package installer and resolver
  ];
}
