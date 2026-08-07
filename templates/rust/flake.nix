{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              rustc
              cargo
              rust-analyzer
              clippy
              rustfmt
              cargo-watch
              cargo-nextest

              # Native dependencies
              pkg-config
              openssl
            ];

            # Prevent LD_LIBRARY_PATH pollution
            shellHook = ''
              echo "rustc $(rustc --version | awk '{print $2}')"
              echo "cargo $(cargo --version | awk '{print $2}')"
            '';

            RUST_BACKTRACE = "1";
          };
        }
      );
    };
}
