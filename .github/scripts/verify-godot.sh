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
wget -q "${base}/SHA512-SUMS.txt" -O "${workdir}/SHA512-SUMS.txt"
(
  cd "$workdir"
  grep -F " ${archive}" SHA512-SUMS.txt | sha512sum -c -
  sha512sum "$archive"
  unzip -q "$archive"
)
cmp "${workdir}/Godot_v${version}_linux.x86_64" "$(command -v godot)"
godot --version | grep -q '^4\.7\.2\.stable'
