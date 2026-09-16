{ inputs, pkgs, ... }:
let
  # The upstream flake's vendor hash was generated with an older
  # fetch-cargo-vendor-util; refresh it for the nixpkgs used by this host.
  fastpotifyRaw =
    inputs.fastpotify.packages.${pkgs.stdenv.hostPlatform.system}.fastpotify.overrideAttrs
      (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.perl ];
        postPatch = (old.postPatch or "") + ''
          ${pkgs.perl}/bin/perl -0pi -e 's{let http = reqwest::Client::builder\(\).*?\.expect\("unable to build the HTTP client"\);}{let mut http_builder = reqwest::Client::builder();\n        http_builder = http_builder.user_agent(concat!("fastpotify/", env!("CARGO_PKG_VERSION"))).timeout(Duration::from_secs(30));\n        if let Ok(proxy_url) = std::env::var("FASTPOTIFY_HTTP_PROXY") {\n            if !proxy_url.trim().is_empty() {\n                match reqwest::Proxy::all(&proxy_url) {\n                    Ok(proxy) => http_builder = http_builder.proxy(proxy),\n                    Err(error) => log::warn!("Ignoring invalid FASTPOTIFY_HTTP_PROXY: {error}"),\n                }\n            }\n        }\n        let http = http_builder.build().expect("unable to build the HTTP client");}s' \
            src/backend.rs
        '';
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          pname = "fastpotify";
          version = "0.7.1";
          src = inputs.fastpotify;
          hash = "sha256-DrwPRPGr2QBXpTKJmCSHLnOJAymwuN7SKKqEYlNTQHc=";
        };
      });
  fastpotifyProxyLauncher = pkgs.writeShellScriptBin "fastpotify-proxy" ''
    export FASTPOTIFY_HTTP_PROXY="http://127.0.0.1:2080"
    exec \
      ${fastpotifyRaw}/bin/fastpotify "$@"
  '';
  fastpotify = fastpotifyRaw.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      sed -i \
        's#^Exec=fastpotify %u$#Exec=${fastpotifyProxyLauncher}/bin/fastpotify-proxy %u#' \
        "$out/share/applications/fastpotify.desktop"
    '';
  });
in
{
  home.packages = with pkgs; [
    spotify
    fastpotify
    fastpotifyProxyLauncher
  ];
}
