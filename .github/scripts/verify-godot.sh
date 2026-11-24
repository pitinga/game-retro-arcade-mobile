#!/usr/bin/env bash
set -euo pipefail

# Confere que o executável instalado pela action é exatamente o release
# oficial cujo SHA-512 foi publicado pelo projeto Godot.
version=4.7.2-stable
archive="Godot_v${version}_linux.x86_64.zip"
base="https://github.com/godotengine/godot-builds/releases/download/${version}"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

wget -q "${base}/${archive}" -O "${workdir}/${archive}"
expected="9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65"
(
  cd "$workdir"
  printf '%s  %s\n' "$expected" "$archive" | sha512sum -c -
  sha512sum "$archive"
  unzip -q "$archive"
)
cmp "${workdir}/Godot_v${version}_linux.x86_64" "$(command -v godot)"
godot --version | grep -q '^4\.7\.2\.stable'
