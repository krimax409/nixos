{ pkgs, ... }:
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

    ## Native deps (used by Rust/Go CGO)
    pkg-config
    openssl

    ## Python
    python3
    python312Packages.ipython
    uv # Python package installer and resolver
  ];
}
