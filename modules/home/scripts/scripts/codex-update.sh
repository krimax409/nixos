#!/usr/bin/env bash
set -euo pipefail

url=${CODEX_UPDATE_URL:-https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
root=${CODEX_UPDATE_ROOT:-$data_home/codex}
mkdir -p "$root/versions"
exec 9> "$root/.update.lock"
flock 9
work=$(mktemp -d "$root/.update.XXXXXXXX")
trap 'rm -rf "$work"' EXIT

curl --fail --location --silent --show-error --retry 2 --connect-timeout 30 --max-time 600 --output "$work/chatgpt.deb" "$url"
version=$(dpkg-deb --field "$work/chatgpt.deb" Version)
if [[ ! $version =~ ^[a-zA-Z0-9][a-zA-Z0-9.+:~_-]*$ ]]; then
    printf 'codex-update: invalid package version: %s\n' "$version" >&2
    exit 1
fi
dpkg-deb --extract "$work/chatgpt.deb" "$work/payload"
app="$work/payload/usr/lib/chatgpt"
test -x "$app/ChatGPT"
test -f "$app/resources/app.asar"
test -f "$work/payload/usr/share/pixmaps/chatgpt.png"

perl -0e '
  my $path = shift @ARGV;
  open my $in, "<", $path or die "cannot read $path: $!";
  binmode $in;
  local $/;
  my $data = <$in>;
  close $in;

  for my $old (
    q#this.ensureWatching(t,o)#,
    q#this.ensureWatching(r,o,i.signal)#,
    q#this.ensureWatching({commonDir:r.commonDir,root:r.root},t)#
  ) {
    my $first = index($data, $old);
    if ($first < 0) {
      warn "codex-update: Git-worker patch target absent: $old\n";
      next;
    }
    die "codex-update: Git-worker patch target ambiguous: $old\n"
      if index($data, $old, $first + length($old)) >= 0;
    my $new = "Promise.resolve()" . (" " x (length($old) - length("Promise.resolve()")));
    substr($data, $first, length($old), $new);
  }

  open my $out, ">", $path or die "cannot write $path: $!";
  binmode $out;
  print {$out} $data;
  close $out;
' "$app/resources/app.asar"

if [[ ! -e $root/versions/$version ]]; then
    mv "$work/payload" "$root/versions/$version"
fi

launcher=${CODEX_LAUNCHER:-chatgpt}
mkdir -p "$data_home/applications"
desktop_tmp=$(mktemp "$data_home/applications/.chatgpt.XXXXXXXX")
trap 'rm -rf "$work"; rm -f "$desktop_tmp" "$root/current.new"' EXIT
cat > "$desktop_tmp" << EOF
[Desktop Entry]
Type=Application
Name=ChatGPT
Exec=$launcher %U
Icon=$root/current/usr/share/pixmaps/chatgpt.png
Terminal=false
Categories=Development;
EOF
chmod 644 "$desktop_tmp"

ln -s "versions/$version" "$root/current.new"
mv -Tf "$root/current.new" "$root/current"
mv -f "$desktop_tmp" "$data_home/applications/chatgpt.desktop"
printf 'codex-update: installed %s (previous versions retained in %s)\n' "$version" "$root/versions"
