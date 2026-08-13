{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  primeAgent = pkgs.buildNpmPackage rec {
    pname = "prime-agent";
    version = "0.7.1";

    src = pkgs.fetchurl {
      url = "https://github.com/PrimeIntellect-ai/prime-agent/releases/download/v${version}/prime-agent-${version}.tgz";
      hash = "sha256-1oYSyDI5yq+rcsx2xVrFcr/QegWeqPvSo92+HytV3Ns=";
    };

    # Upstream's release tarball omits its lockfile. This lockfile was generated
    # from that exact tarball. Three upstream R2 URLs are replaced by the
    # corresponding assets from the same GitHub release because the R2 endpoint
    # stalls Nix's fetcher; integrity hashes remain unchanged.
    postPatch = ''
      cp ${./prime-agent-package-lock.json} package-lock.json
      substituteInPlace package.json \
        --replace-fail \
          "https://pub-728493de92a943e2a9b2d17b4719f318.r2.dev/releases/v0.7.1/" \
          "https://github.com/PrimeIntellect-ai/prime-agent/releases/download/v0.7.1/"
    '';

    npmDepsHash = "sha256-SXRiQ1ca2h9qDatz/SespnY1NauVYUxfEj7uQTdoGfI=";
    npmDepsFetcherVersion = 1;
    npmFlags = [ "--ignore-scripts" ];
    dontNpmBuild = true;
    makeCacheWritable = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postFixup = ''
      wrapProgram $out/bin/prime-agent \
        --prefix PATH : ${
          pkgs.lib.makeBinPath [
            pkgs.nodejs_22
            pkgs.python3
            pkgs.git
            pkgs.bashNonInteractive
            pkgs.coreutils
          ]
        }
    '';

    meta = {
      description = "Coding agent CLI with IPython-backed tools";
      homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
      license = pkgs.lib.licenses.mit;
      mainProgram = "prime-agent";
      platforms = pkgs.lib.platforms.linux;
    };
  };

  models = {
    providers.a6api = {
      baseUrl = "https://api-direct.a6api.com/v1";
      api = "openai-completions";
      apiKey = "!cat /home/k/.config/prime-agent-secrets/a6api-review.key";
      authHeader = true;
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
      };
      models = [
        {
          id = "glm-5.2";
          name = "GLM 5.2 via A6API";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 202752;
          maxTokens = 32768;
        }
        {
          id = "DeepSeek-V4-Flash-0731";
          name = "DeepSeek V4 Flash 0731 via A6API";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 163840;
          maxTokens = 32768;
        }
        {
          id = "claude-opus-5";
          name = "Claude Opus 5 via A6API";
          reasoning = true;
          input = [
            "text"
            "image"
          ];
          contextWindow = 200000;
          maxTokens = 32768;
        }
      ];
    };
  };
in
{
  config = lib.mkIf (osConfig.networking.hostName == "desktop") {
    home.packages = [ primeAgent ];
    home.file.".prime/agent/models.json".text = builtins.toJSON models;
  };
}
