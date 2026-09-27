{ rustPlatform, fetchFromGitHub, lib }:
rustPlatform.buildRustPackage {
  pname = "secretspec-main";
  version = "0.19.1-main-98da929";
  src = fetchFromGitHub {
    owner = "cachix";
    repo = "secretspec";
    rev = "98da9292b31817c3a4c696d0112eacd13905651e";
    hash = "sha256-mD6sLKXLqJazvIj9zhhfKYhzb6zHL5wtL+5s7TgcHj4=";
  };
  cargoHash = "sha256-BP9u86MyhIUxyYlOjzJHRNNRabAwbCT0RoPTYrmVVQU=";
  cargoBuildFlags = [
    "-p"
    "secretspec"
  ];
  buildFeatures = [
    "cli"
    "infisical"
  ];
  doCheck = false;
  meta = {
    description = "SecretSpec built from upstream main";
    homepage = "https://github.com/cachix/secretspec";
    license = lib.licenses.asl20;
    mainProgram = "secretspec";
  };
}
