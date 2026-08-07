{
  description = "Node.js development environment";

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
              # Pin the major version per project; nodejs_22 is the previous LTS.
              nodejs
              pnpm

              typescript
              typescript-language-server
              vscode-langservers-extracted
              biome

              # node-gyp needs a C toolchain and python for native modules
              node-gyp
              python3
              gcc
              pkg-config
            ];

            shellHook = ''
              echo "node $(node --version)"
              echo "pnpm $(pnpm --version)"

              # Keep globally installed npm binaries inside the project
              export NPM_CONFIG_PREFIX="$PWD/.npm-global"
              export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
            '';
          };
        }
      );
    };
}
