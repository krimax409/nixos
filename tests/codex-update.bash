#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/modules/home/scripts/scripts/codex-update.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CODEX_TEST_LOG"
while (($#)); do
  case "$1" in
    --output) output=$2; shift 2 ;;
    *) shift ;;
  esac
done
if [[ ${FAKE_PAUSE:-} == 1 ]]; then
  touch "$CODEX_TEST_READY"
  while [[ ! -e $CODEX_TEST_RELEASE ]]; do sleep 0.02; done
fi
printf 'fake deb' > "$output"
EOF
cat > "$tmp/bin/dpkg-deb" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --field)
    printf '%s\n' "${FAKE_VERSION:-26.917.62051}"
    ;;
  --extract)
    dest=$3
    mkdir -p "$dest/usr/lib/chatgpt/resources" "$dest/usr/share/pixmaps"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*"\n' > "$dest/usr/lib/chatgpt/ChatGPT"
    chmod +x "$dest/usr/lib/chatgpt/ChatGPT"
    if [[ ${FAKE_NO_PATCH:-} == 1 ]]; then
      printf '%s\n' 'this.ensureWatching(t,o)' 'this.ensureWatching(r,o,i.signal)' > "$dest/usr/lib/chatgpt/resources/app.asar"
    else
      printf '%s\n' 'this.ensureWatching(t,o)' 'this.ensureWatching(r,o,i.signal)' 'this.ensureWatching({commonDir:r.commonDir,root:r.root},t)' > "$dest/usr/lib/chatgpt/resources/app.asar"
    fi
    if [[ ${FAKE_DUPLICATE_PATCH:-} == 1 ]]; then
      printf '%s\n' 'this.ensureWatching(t,o)' >> "$dest/usr/lib/chatgpt/resources/app.asar"
    fi
    printf 'icon' > "$dest/usr/share/pixmaps/chatgpt.png"
    ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$tmp/bin/"*

run_update() {
  PATH="$tmp/bin:$PATH" HOME="$tmp/home" XDG_DATA_HOME="$tmp/data" CODEX_UPDATE_ROOT="$tmp/codex" CODEX_UPDATE_URL="https://example.invalid/latest/chatgpt_amd64.deb" CODEX_TEST_LOG="$tmp/curl.log" bash "$script"
}

run_update
test -L "$tmp/codex/current"
test -x "$tmp/codex/current/usr/lib/chatgpt/ChatGPT"
test -f "$tmp/codex/current/usr/share/pixmaps/chatgpt.png"
test "$(readlink "$tmp/codex/current")" = 'versions/26.917.62051'
test "$(find "$tmp/codex/versions" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 1
if grep -q 'ensureWatching' "$tmp/codex/current/usr/lib/chatgpt/resources/app.asar"; then
  printf 'Git watcher patch missing\n' >&2
  exit 1
fi
grep -q 'latest/chatgpt_amd64.deb' "$tmp/curl.log"

# Re-running the same version must not overwrite a known-good installation.
printf 'sentinel' > "$tmp/codex/versions/26.917.62051/sentinel"
run_update
test -f "$tmp/codex/current/sentinel"

# A failed download must leave the old symlink and version intact.
mv "$tmp/bin/curl" "$tmp/bin/curl.real"
cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
exit 23
EOF
chmod +x "$tmp/bin/curl"
if run_update; then
  printf 'failed download succeeded\n' >&2
  exit 1
fi
test "$(readlink "$tmp/codex/current")" = 'versions/26.917.62051'
test -f "$tmp/codex/current/sentinel"

mv "$tmp/bin/curl.real" "$tmp/bin/curl"
FAKE_VERSION=26.918.1 run_update
test "$(readlink "$tmp/codex/current")" = 'versions/26.918.1'
test -f "$tmp/codex/versions/26.917.62051/sentinel"
test -f "$tmp/data/applications/chatgpt.desktop"
grep -Fq "Icon=$tmp/codex/current/usr/share/pixmaps/chatgpt.png" "$tmp/data/applications/chatgpt.desktop"

# A malformed release must not replace the installed one.
if FAKE_VERSION='../escape' run_update; then
  printf 'invalid version succeeded\n' >&2
  exit 1
fi
test "$(readlink "$tmp/codex/current")" = 'versions/26.918.1'

# A patch ambiguity must not switch current to the new release.
FAKE_VERSION=26.919.1 FAKE_DUPLICATE_PATCH=1 run_update && {
  printf 'ambiguous patch succeeded\n' >&2
  exit 1
}
test "$(readlink "$tmp/codex/current")" = 'versions/26.918.1'
test ! -d "$tmp/codex/versions/26.919.1"

# A release missing a Git-worker target installs with a warning.
FAKE_VERSION=26.920.1 FAKE_NO_PATCH=1 run_update 2> "$tmp/warnings"
test "$(readlink "$tmp/codex/current")" = 'versions/26.920.1'
test -x "$tmp/codex/current/usr/lib/chatgpt/ChatGPT"
grep -q 'Git-worker patch target absent' "$tmp/warnings"

# A second invocation cannot complete while the first is downloading.
FAKE_VERSION=26.921.1 FAKE_PAUSE=1 CODEX_TEST_READY="$tmp/ready" CODEX_TEST_RELEASE="$tmp/release" \
  run_update > "$tmp/first.log" 2>&1 &
first=$!
for ((i=0; i<100; i++)); do
  [[ -e $tmp/ready ]] && break
  sleep 0.02
done
test -e "$tmp/ready"
FAKE_VERSION=26.922.1 run_update > "$tmp/second.log" 2>&1 &
second=$!
sleep 0.2
if ! kill -0 "$second" 2>/dev/null; then
  printf 'concurrent updater finished before the first released its lock\n' >&2
  touch "$tmp/release"
  wait "$first" || true
  wait "$second" || true
  exit 1
fi
touch "$tmp/release"
wait "$first"
wait "$second"
test "$(readlink "$tmp/codex/current")" = 'versions/26.922.1'
test -x "$tmp/codex/versions/26.921.1/usr/lib/chatgpt/ChatGPT"
test -x "$tmp/codex/versions/26.922.1/usr/lib/chatgpt/ChatGPT"

# Home Manager must expose exactly one codex-update package.
count=$(nix eval --raw --no-write-lock-file \
  --apply 'ps: toString (builtins.length (builtins.filter (p: p.name == "codex-update") ps))' \
  'path:.#nixosConfigurations.laptop.config.home-manager.users.krim.home.packages')
test "$count" = 1 || { printf 'expected one codex-update package, found %s\n' "$count" >&2; exit 1; }

printf '%s\n' 'codex-update: pass'
