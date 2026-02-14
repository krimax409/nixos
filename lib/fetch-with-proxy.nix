{ pkgs }:
# Fetches a URL with fallback to proxy if direct download fails.
# Used for sources blocked in some regions (e.g. JetBrains from Russia).
src:
pkgs.stdenvNoCC.mkDerivation {
  name = src.name;
  nativeBuildInputs = [
    pkgs.curl
    pkgs.cacert
  ];
  outputHash = src.outputHash;
  outputHashAlgo = src.outputHashAlgo;
  outputHashMode = "flat";
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  buildCommand = ''
    url="${builtins.head src.urls}"
    echo "Trying direct download: $url"
    if curl --fail -L --connect-timeout 10 -o "$out" "$url" 2>&1; then
      echo "Direct download succeeded"
    else
      echo "Direct download failed, trying proxy..."
      curl --fail -L --proxy http://127.0.0.1:2080 -o "$out" "$url"
    fi
  '';
}
