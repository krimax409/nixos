# Development Environment Templates

Базовые шаблоны flake.nix для быстрого старта проектов с direnv.

## Использование

```bash
# В корне нового проекта (go, rust или node)
cp -a /etc/nixos/nixos-config/templates/rust/. .

# direnv автоматически активирует окружение при входе в каталог
direnv allow
```

`cp -a ... /.` копирует и `.envrc` тоже — с `/*` скрытые файлы не попадут.

## Go

Шаблон включает:
- `go`, `gopls`, `delve`, `golangci-lint`, `gofumpt`
- CGO зависимости: `gcc`, `pkg-config`

После активации:
```bash
go mod init github.com/username/project
go mod tidy
```

## Rust

Шаблон включает:
- `rustc`, `cargo`, `rust-analyzer`, `clippy`, `rustfmt`
- Утилиты: `cargo-watch`, `cargo-nextest`
- Нативные зависимости: `pkg-config`, `openssl`

После активации:
```bash
cargo init
cargo build
```

## Node.js

Шаблон включает:
- `nodejs` (npm, npx), `pnpm`
- `typescript`, `typescript-language-server`, `vscode-langservers-extracted`, `biome`
- Для нативных модулей: `node-gyp`, `python3`, `gcc`, `pkg-config`

После активации:
```bash
pnpm init
pnpm add -D vitest
```

`shellHook` уводит `npm i -g` в `.npm-global` внутри проекта, чтобы глобальные
установки не расползались по `$HOME`. Добавь этот каталог в `.gitignore`.

Для другой мажорной версии замени `nodejs` на `nodejs_22` в `buildInputs`.

## Переопределение версий

Если проекту нужна конкретная версия toolchain, измени `inputs.nixpkgs.url` в `flake.nix`:

```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
# или пин на конкретный коммит
nixpkgs.url = "github:NixOS/nixpkgs/abc123...";
```

Для Rust с nightly или конкретной версии добавь `rust-overlay`:

```nix
inputs.rust-overlay.url = "github:oxalica/rust-overlay";
# затем в buildInputs:
(rust-bin.stable."1.84.0".default)
# или
(rust-bin.fromRustupToolchainFile ./rust-toolchain.toml)
```
