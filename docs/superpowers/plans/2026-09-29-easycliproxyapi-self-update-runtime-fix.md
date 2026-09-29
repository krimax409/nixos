# EasyCLIProxyAPI self-update runtime fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make EasyCLIProxyAPI's self-updater able to validate and launch upstream Linux releases inside the Nix runtime without deleting OAuth/configuration data.

**Architecture:** Keep the existing Nix package and user-data payload layout. Extend the generated launcher to export a library path containing the package's GUI dependencies (plus the GCC runtime) before executing the application, so updater children inherit it. Replace destructive payload reseeding with a staged merge that preserves user data and only replaces the immutable seeded application/core files.

**Tech Stack:** Nix flakes, Nix `stdenv.mkDerivation`, `autoPatchelfHook`, Bash launcher, systemd user service, `readelf`/`ldd`, EasyCLIProxyAPI self-update flow.

**Spec:** Root-cause and review findings from the EasyCLIProxyAPI v0.3.10 update failure; no external design document.

## Global Constraints

- Do not run the EasyCLIProxyAPI GUI update from the agent; the user will click it after the Nix change is applied.
- Do not modify or expose OAuth files, API keys, `config.yaml`, `config.toml`, usage databases, or Git history.
- Do not use runtime `patchelf` on staged/updater binaries; inherited `LD_LIBRARY_PATH` must cover the staging validation and relaunch path.
- Do not add `webkitgtk_4_1` or other GUI libraries globally to `programs.nix-ld` unless the launcher approach fails in a controlled test.
- Do not use `rm -rf payload`; use a separate staging directory and atomic replacement only for the seeded application payload, preserving existing user data.
- Preserve `GTK_CSD=0`, the existing systemd `GSETTINGS_SCHEMA_DIR`, and the current service configuration, except for the intentional `ExitType=cgroup` addition covered by Task 3a.
- Validate with Nix evaluation/build and a live service/API smoke test before asking the user to update.

---

### Task 1: Add inherited Nix library path and safe payload seeding

**Files:**
- Modify: `/home/k/nixos/pkgs/easycliproxyapi.nix:1-112`
- Test: shell-level generated-launcher checks and Nix build output

**Interfaces:**
- Consumes: existing `buildInputs`, Nix `lib.makeLibraryPath`, the existing payload and user-data directories.
- Produces: a launcher at `$out/bin/easycliproxyapi` that exports a runtime `LD_LIBRARY_PATH` before `exec`, seeds missing immutable files without deleting `payload/oauth`, `payload/config.toml`, or `payload/usage-records`, and executes the current payload binary.

- [ ] **Step 1: Copy the package file to a candidate and inspect the current launcher before editing**

Run:

```bash
cd /home/k/nixos
cp pkgs/easycliproxyapi.nix pkgs/easycliproxyapi.nix.new
```

Keep the original untouched until the candidate validates.

- [ ] **Step 2: Edit the candidate's dependency list and launcher**

Keep the existing package inputs and add `stdenv.cc.cc.lib` to the library-path expression without adding a second `buildInputs` entry. In the launcher, replace the destructive block beginning at `if [ ! -x "''${payload_dir}/EasyCLIProxyAPI" ]; then` with a staging merge that copies the Nix-seeded files into `payload.new`, copies existing payload data into it when present, then atomically swaps only after all copies succeed:

```nix
    app_libs="${lib.makeLibraryPath (buildInputs ++ [ stdenv.cc.cc.lib ])}"
    export LD_LIBRARY_PATH="''${app_libs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    if [ ! -x "''${payload_dir}/EasyCLIProxyAPI" ]; then
      ${coreutils}/bin/rm -rf "''${payload_dir}.new"
      ${coreutils}/bin/mkdir -p "''${payload_dir}.new/cpa-core"
      if [ -d "''${payload_dir}" ]; then
        ${coreutils}/bin/cp -a "''${payload_dir}/." "''${payload_dir}.new/"
      fi
      ${coreutils}/bin/cp "${placeholder "out"}/lib/easycliproxyapi/EasyCLIProxyAPI" "''${payload_dir}.new/EasyCLIProxyAPI"
      ${coreutils}/bin/cp "${placeholder "out"}/lib/easycliproxyapi/core-version.txt" "''${payload_dir}.new/core-version.txt"
      ${coreutils}/bin/cp "${placeholder "out"}/lib/easycliproxyapi/portable-app.json" "''${payload_dir}.new/portable-app.json"
      ${coreutils}/bin/cp -a "${placeholder "out"}/lib/easycliproxyapi/cpa-core/." "''${payload_dir}.new/cpa-core/"
      ${coreutils}/bin/chmod -R u+rwX "''${payload_dir}.new"
      ${coreutils}/bin/mkdir -p "''${data_dir}"
      ${coreutils}/bin/rm -rf "''${payload_dir}.old"
      ${coreutils}/bin/mv "''${payload_dir}" "''${payload_dir}.old" 2>/dev/null || true
      ${coreutils}/bin/mv "''${payload_dir}.new" "''${payload_dir}"
      ${coreutils}/bin/rm -rf "''${payload_dir}.old"
    fi
```

The implementation must place the `LD_LIBRARY_PATH` export before the application `exec`; it must not put it only in the systemd unit. The merge must preserve the existing payload's `oauth`, `config.toml`, `usage-records`, and any updater backup/staging files. If an atomic swap is implemented, a failed final move must not remove the original payload; do not ignore a failed move of the original directory.

- [ ] **Step 3: Run syntax and static checks on the candidate**

Run:

```bash
cd /home/k/nixos
nix-instantiate --eval --strict --expr 'let p = import ./pkgs/easycliproxyapi.nix; in builtins.typeOf p'
git diff --no-index -- /dev/null pkgs/easycliproxyapi.nix.new >/tmp/easycliproxyapi-candidate.diff || true
grep -n 'LD_LIBRARY_PATH\|rm -rf.*payload\|payload.new\|GTK_CSD' pkgs/easycliproxyapi.nix.new
```

Expected: Nix parses the candidate; `LD_LIBRARY_PATH` appears before `exec`; no command deletes the live `payload` directory as part of seeding; `GTK_CSD=0` remains.

- [ ] **Step 4: Build the candidate and inspect the generated launcher**

Run the package build without changing the system:

```bash
cd /home/k/nixos
nix build --no-link --print-out-paths --impure --expr '(import <nixpkgs> {}).callPackage ./pkgs/easycliproxyapi.nix {}' > /tmp/easycliproxyapi-out
out=$(cat /tmp/easycliproxyapi-out)
sed -n '1,120p' "$out/bin/easycliproxyapi"
bash -n "$out/bin/easycliproxyapi"
```

Expected: the generated script contains concrete Nix store library paths including WebKitGTK, libsoup, and the GCC runtime; the script passes Bash syntax validation.

- [ ] **Step 5: Validate and install the candidate package change**

After the candidate checks pass, review only the intended diff, then replace the tracked file using the repository's normal edit workflow. Validate the final file with:

```bash
cd /home/k/nixos
git diff --check
git diff -- pkgs/easycliproxyapi.nix
nix flake check --no-build
```

Do not commit or push unless separately requested.

### Task 2: Apply the Nix profile and verify the launcher in place

**Files:**
- No additional repository files expected.
- Runtime: generated Home Manager/Nix profile and the user service.

**Interfaces:**
- Consumes: the validated `pkgs/easycliproxyapi.nix` launcher.
- Produces: an active service whose application process has the Nix GUI library path and whose API remains available.

- [ ] **Step 1: Build/dry-run the relevant host profile**

Run the repository's documented non-activating checks first:

```bash
cd /home/k/nixos
nixos-rebuild build --flake .#desktop
```

If the active machine is the `laptop` host, use `nixos-rebuild build --flake .#laptop` instead; do not guess the host if the command rejects the selected name.

- [ ] **Step 2: Apply the profile through the existing documented command**

Run the appropriate configured command (`nft`/`nfs`) or the host's established Home Manager/NixOS switch command. Do not alter sudoers or unrelated dirty files. If activation requires confirmation or fails, stop and report the exact error.

- [ ] **Step 3: Restart and inspect the user service**

Run:

```bash
systemctl --user restart easycliproxyapi.service
systemctl --user is-active easycliproxyapi.service
pid=$(pgrep -u "$USER" -f '/payload/EasyCLIProxyAPI' | head -1)
tr '\0' '\n' <"/proc/$pid/environ" | grep '^LD_LIBRARY_PATH='
ss -ltn '( sport = :8317 )'
```

Expected: service active, `LD_LIBRARY_PATH` contains Nix paths for `webkitgtk_4_1`, `libsoup_3`, and `stdenv.cc.cc.lib`, port `8317` listening on loopback.

- [ ] **Step 4: Run existing payload and upstream-style staging smoke tests**

Run the current payload under the generated launcher and, if the previous staging directory is still available, run its staged binary with the same library path:

```bash
out=$(cat /tmp/easycliproxyapi-out)
LD_LIBRARY_PATH="$(tr '\0' '\n' <"/proc/$pid/environ" | sed -n 's/^LD_LIBRARY_PATH=//p')" \
  /tmp/EasyCLIProxyAPI-update-v0.3.10-35087-1790628764050397964/staging/EasyCLIProxyAPI --version || true
```

The staged binary must no longer fail immediately with `libwebkit2gtk-4.1.so.0 not found`; if it reports a different runtime/UI issue, capture it and stop before updating.

### Task 3a: Let the self-update helper survive normal GUI exit (systemd)

**Files:**
- Modify: `/home/k/nixos/modules/home/packages/gui.nix` (`systemd.user.services.easycliproxyapi.Service`)

**Interfaces:**
- Consumes: the confirmed root cause — the updater is a plain child in the service cgroup; the GUI writes `update-helper-started.ack` and exits 0, and with `ExitType=main` + `KillMode=control-group` systemd kills the helper before it writes `update-started.ack`.
- Produces: a generated unit with `ExitType=cgroup`, unchanged `ExecStart`/`GSETTINGS_SCHEMA_DIR`/`Restart=on-failure`, and `KillMode` left at the `control-group` default. Do not use `KillMode=process` or `Restart=always`.

- [ ] **Step 1: Add `ExitType = "cgroup";` to the Service block**

- [ ] **Step 2: Build and inspect the generated unit**

```bash
cd /home/k/nixos
nixos-rebuild build --flake .#laptop
```

The generated `easycliproxyapi.service` must contain `ExitType=cgroup` and keep `Restart=on-failure`, `ExecStart`, `ExecStartPre`, and `GSETTINGS_SCHEMA_DIR`.

- [ ] **Step 3: Synthetic verification (optional, non-invasive)**

A `systemd-run --user` transient unit with `Type=simple`, `KillMode=control-group`, `ExitType=cgroup`, whose main process spawns a `setsid` child and exits 0, must stay active until the child exits and must not restart. The same unit under default `ExitType=main` must go inactive immediately and the child must be killed before finishing. Do not restart the real service or run the GUI update.

### Task 3: User-controlled update and end-to-end validation

**Files:**
- No repository changes expected.

**Interfaces:**
- Consumes: active launcher and pre-update backup `/home/k/.local/state/easycliproxyapi-backups/pre-update-20260928-234941.tar.gz`.
- Produces: user-updated EasyCLIProxyAPI app/core with preserved auth/config and a verified local API.

- [ ] **Step 1: Create a fresh backup immediately before the GUI update**

Stop the user service, create a new mode-0600 archive of `/home/k/.local/share/easycliproxyapi`, verify it with `tar -tzf`, and start the service again. Keep all prior backups.

- [ ] **Step 2: User clicks Desktop Application → Update Now**

Do not click the GUI update from the agent. Wait for the user to confirm the app has closed/reopened.

- [ ] **Step 3: Verify application version and payload preservation**

Run:

```bash
python - <<'PY'
from pathlib import Path
import json
p=Path.home()/'.local/share/easycliproxyapi/payload'
print(json.loads((p/'portable-app.json').read_text())['version'])
print((p/'core-version.txt').read_text().strip())
for name in ('config.toml','oauth','usage-records'):
 print(name, (p/name).exists())
PY
```

Expected: app version `0.3.10`; the new core marker is present; config, OAuth, and usage records still exist. If the version remains old, do not press Update Now repeatedly; collect updater workspace/logs and stop.

- [ ] **Step 4: Verify service/API and model requests**

Run the service check and `/v1/models` request. Then test `claude-sonnet-5` and `claude-opus-5-5` with a minimal non-secret request, recording only HTTP status and a short sanitized error. Do not print API keys or response content beyond a fixed status marker.

- [ ] **Step 5: Record rollback procedure without executing it**

If the updated GUI or core fails, stop the service and restore the latest mode-0600 backup into `/home/k/.local/share/easycliproxyapi`, then restart the service. Do not execute rollback unless the user explicitly asks or the service cannot be recovered by normal restart.

---

## Self-review

- Coverage: inherited runtime libraries, GCC runtime, safe payload reseeding, Nix build/evaluation, active service checks, user-controlled GUI update, version checks, API smoke tests, and rollback are all covered.
- Placeholder scan: no TODO/TBD or unspecified validation steps remain.
- Scope: only one repository package file plus the `ExitType=cgroup` service directive are modified; global nix-ld, other systemd settings, credentials, and unrelated dirty files are intentionally untouched.
- Safety: no update click, commit, push, deletion of user data, or secret output is performed by the plan.
