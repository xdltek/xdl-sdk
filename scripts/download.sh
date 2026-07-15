#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: bash download.sh <url> <output-file>" >&2
  exit 2
fi

url="$1"
output_file="$2"
tmp_file="${output_file}.tmp"

mkdir -p "$(dirname "$output_file")"
rm -f "$tmp_file"

if command -v wget >/dev/null 2>&1; then
  wget -O "$tmp_file" "$url"
elif command -v curl >/dev/null 2>&1; then
  curl -fL "$url" -o "$tmp_file"
else
  echo "Missing downloader: install wget or curl." >&2
  exit 1
fi

mv -f "$tmp_file" "$output_file"
echo "Downloaded: $output_file"
