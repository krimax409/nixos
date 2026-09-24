# Codex Desktop Mutable Updater Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the hash-pinned Codex Desktop derivation and provide a manually invoked `codex-update` command that installs the current OpenAI Linux `.deb` outside the Nix store while preserving rollback versions.

**Architecture:** NixOS/Home Manager will package only a stable runtime wrapper, desktop entry, update script, and required FHS libraries; the updater will download `latest/chatgpt_amd64.deb` into a temporary directory, extract and patch `app.asar`, validate the executable, and atomically update `~/.local/share/codex/current`. Old versions remain under `~/.local/share/codex/versions`. No timer or automatic update service will be added.

**Tech Stack:** Nix flakes, Home Manager, Nix `buildFHSEnv`, Bash, `dpkg-deb`, Electron `.deb`, existing Perl `app.asar` patch.

**Spec:** This plan implements the approved manual-update hybrid design from the conversation; there is no separate design document.

## Global Constraints

- The Codex download URL remains `https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb`.
- The mutable installation root is `$XDG_DATA_HOME/codex` when `XDG_DATA_HOME` is set, otherwise `$HOME/.local/share/codex`.
- The updater must never replace `current` until extraction, patching, and executable validation succeed.
- Previous installed versions must remain available for manual rollback.
- No systemd timer or automatic update check is added.
- `nixos-rebuild` must not fetch the Codex `.deb` or depend on its current contents.
- Existing unrelated dirty changes in `modules/home/packages/gui.nix` must be preserved.

---

### Task 1: Add a testable Codex updater script

**Files:**
- Create: `modules/home/scripts/scripts/codex-update.sh`
- Create: `tests/codex-update.bash`

**Interfaces:**
- Consumes: `CODEX_UPDATE_ROOT`, `CODEX_UPDATE_URL`, `CODEX_UPDATE_DRY_RUN`, `CODEX_TEST_BIN`, and `CODEX_TEST_LOG` test overrides; production defaults use `$XDG_DATA_HOME/codex` or `$HOME/.local/share/codex` and the OpenAI `latest` URL.
- Produces: executable `codex-update` behavior; installs `$root/versions/<version>`, updates `$root/current`, and exits nonzero without changing `current` on failure.

- [ ] **Step 1: Write the failing test**

Create a Bash test that builds fake `curl`, `dpkg-deb`, `perl`, and `file` commands in a temporary `PATH`. The fake `dpkg-deb --extract` must create `usr/lib/chatgpt/ChatGPT`, `usr/share/applications/chatgpt.desktop`, `usr/share/pixmaps/chatgpt.png`, and `usr/lib/chatgpt/resources/app.asar`; the fake `curl` must copy a fixture marker and log the URL; the fake `perl` must log the patch target and exit successfully. Assert that running the script creates a version directory, a `current` symlink, the launcher payload, and uses the `latest` URL. Add a second case where fake `perl` fails and assert that an existing `current` symlink still points to the old version.

```bash
CODEX_UPDATE_ROOT="$root/codex" CODEX_UPDATE_URL="https://example.invalid/latest/chatgpt_amd64.deb" CODEX_TEST_BIN="$fake_bin" CODEX_TEST_LOG="$log" bash "$script"
test -L "$root/codex/current"
test -x "$root/codex/current/usr/lib/chatgpt/ChatGPT"
grep -q 'latest/chatgpt_amd64.deb' "$log"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/codex-update.bash`
Expected: FAIL because `modules/home/scripts/scripts/codex-update.sh` does not exist.

- [ ] **Step 3: Write the minimal updater implementation**

Implement `codex-update.sh` with `set -euo pipefail`; resolve the root; create a temporary directory under the root; download with `curl --fail --location --silent --show-error --retry 2 --connect-timeout 30 --max-time 600 --output`; validate with `dpkg-deb --info`; extract with `dpkg-deb --extract`; require `usr/lib/chatgpt/ChatGPT` and `usr/lib/chatgpt/resources/app.asar`; derive a version from `usr/share/doc/chatgpt/changelog.gz` when available and otherwise use a UTC timestamp; apply the existing three `app.asar` replacements using Perl while requiring each target to occur exactly once; copy the extracted tree to `versions/<version>`; create `current.new` and atomically rename it to `current`; remove only the temporary directory. Use `CODEX_TEST_BIN` as an optional command directory prefix so the test can replace external commands without affecting production.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/codex-update.bash`
Expected: `codex-update: pass` and exit code 0.

- [ ] **Step 5: Commit the updater independently**

```bash
git add modules/home/scripts/scripts/codex-update.sh tests/codex-update.bash
git commit -m "feat: add mutable Codex updater"
```

### Task 2: Replace the Nix hash-pinned package with a runtime wrapper

**Files:**
- Modify: `modules/home/packages/gui.nix:143-275`
- Modify: `modules/home/packages/gui.nix:278-285`

**Interfaces:**
- Consumes: mutable installation at `$XDG_DATA_HOME/codex/current` or `$HOME/.local/share/codex/current`.
- Produces: Nix package `codexDesktop` with `bin/chatgpt`, `share/applications/chatgpt.desktop`, `bin/codex-update`, and an FHS runtime containing the same library families currently supplied by `buildInputs`.

- [ ] **Step 1: Replace `codexDesktop` with an FHS runtime package**

Remove `pkgs.fetchurl`, `version`, `autoPatchelfHook`, `dpkg`, the fixed `hash`, and the `app.asar` build-time patch. Define `codexDesktop = pkgs.buildFHSEnv { name = "codex-desktop"; targetPkgs = pkgs: with pkgs; [ alsa-lib at-spi2-atk at-spi2-core cairo cups dbus expat gdk-pixbuf glib gtk3 libdrm libgbm libnotify libsecret libusb1 libX11 libXcomposite libXcursor libXdamage libXext libXfixes libXrandr libxcb libxkbcommon libxshmfence libxtst nspr nss pango stdenv.cc.cc systemd vulkan-loader wayland xdg-utils git ]; runScript = "${codexRoot}/current/usr/lib/chatgpt/ChatGPT"; profile = `...`; }` where the profile exports `CODEX_ROOT` and sets `PATH` to the Nix runtime tools. Use `pkgs.writeShellScriptBin` for a wrapper if the exact `buildFHSEnv` invocation needs to preserve arguments and the mutable path; do not make the Nix build inspect the mutable path.

- [ ] **Step 2: Add the updater to `home.packages` and add a desktop entry**

Add a `codexUpdate = pkgs.writeShellScriptBin "codex-update" (builtins.readFile ../scripts/scripts/codex-update.sh);` binding or equivalent package. Keep `codexDesktop` in the AI coding package list. Define `xdg.desktopEntries.codex` with `name = "ChatGPT"`, `exec = "${codexDesktop}/bin/codex-desktop %U"`, `icon = "chatgpt"`, `terminal = false`, and `categories = [ "Development" ];`. Install the icon from the mutable `current` tree through the launcher only if Home Manager supports a stable generated path; otherwise use the `.desktop` file created by the updater and document that desktop integration appears after running `codex-update`.

- [ ] **Step 3: Ensure Nix evaluation no longer references a Codex fetch hash**

Run: `grep -R -n -E 'chatgpt_amd64\.deb|codex-desktop.*hash|YlgBiNh|dVNuPxl' modules pkgs`
Expected: no fixed Codex URL/hash derivation remains; the URL appears only inside the updater script.

- [ ] **Step 4: Run the updater test and Nix formatter/evaluation checks**

Run: `bash tests/codex-update.bash`
Run: `nix eval --no-write-lock-file --raw .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath`
Expected: the updater test passes and Nix evaluates without downloading `chatgpt_amd64.deb`.

- [ ] **Step 5: Commit the Nix integration**

```bash
git add modules/home/packages/gui.nix
git commit -m "feat: manage Codex latest release outside Nix"
```

### Task 3: Validate a real install and runtime on the laptop

**Files:**
- No repository file changes expected.
- Remote runtime files: `/home/krim/.local/share/codex/` and generated Home Manager profile.

**Interfaces:**
- Consumes: `codex-update` and `codexDesktop` from Task 2.
- Produces: one real installed current Codex version and a verified launcher; no timer.

- [ ] **Step 1: Run the repository test suite**

Run: `bash tests/wallpaper-toggle.bash && bash tests/win11-start-menu.bash && bash tests/codex-update.bash`
Expected: all three print their `pass` markers and exit 0.

- [ ] **Step 2: Evaluate and build the laptop profile without switching**

Run on the laptop with a temporary clean Git config for the known GitHub URL rewrite:

```bash
nixos-rebuild dry-build --flake /etc/nixos#laptop
```

Expected: the profile evaluates and no hash mismatch for `chatgpt_amd64.deb` occurs.

- [ ] **Step 3: Apply the Home Manager/NixOS configuration**

Run only after the dry-build passes:

```bash
nixos-rebuild switch --flake /etc/nixos#laptop
```

Expected: the active generation changes successfully; the command itself does not download the Codex `.deb`.

- [ ] **Step 4: Install and validate latest Codex manually**

Run:

```bash
codex-update
readlink -f "$HOME/.local/share/codex/current"
command -v chatgpt
chatgpt --version || true
```

Expected: `codex-update` reports an installed version, `current` resolves to a version directory, and the launcher starts or reaches its normal Electron initialization without Nix rebuilding the `.deb`.

- [ ] **Step 5: Verify no timer exists and record rollback instructions**

Run:

```bash
systemctl --user list-timers --all | grep -i codex || true
ls -1 "$HOME/.local/share/codex/versions"
```

Expected: no Codex timer is present; at least the current version is retained. Roll back manually with `ln -sfn "$HOME/.local/share/codex/versions/<version>" "$HOME/.local/share/codex/current"`.

---

## Self-review

- Spec coverage: manual updater, no timer, latest URL without Nix hash, atomic installation, patch preservation, rollback versions, Nix runtime libraries, evaluation/dry-build/switch validation, and laptop end-to-end launch are covered by Tasks 1–3.
- Placeholder scan: no `TODO`, `TBD`, or unspecified error-handling steps remain; all test commands and expected outcomes are concrete.
- Interface consistency: Task 1 creates `codex-update.sh`; Task 2 exposes it as `codex-update`; Task 3 invokes that command and uses the documented `current` path.
- Scope: updater implementation and Nix integration are one feature; laptop validation is a separate deployment task within the same plan and does not add a timer or unrelated refactor.
