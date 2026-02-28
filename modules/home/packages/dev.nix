import ../../../lib/mkModule.nix {
  namespace = "kdk.home";
  name = "packages-dev";
  description = "Dev tools: GCC, Python, LSPs";
  category = "packages";

  cfg = _cfg: { pkgs, ... }: {
    home.packages = with pkgs; [
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

      ## Python
      python3
      python312Packages.ipython
      uv # Python package installer and resolver
    ];
  };
}
