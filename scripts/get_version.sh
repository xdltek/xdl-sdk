#!/usr/bin/env bash
set -euo pipefail

CREATION_TIMESTAMP="/usr/local/rpp/doc/creation_timestamp.txt"

if [[ ! -f "$CREATION_TIMESTAMP" ]]; then
  echo "The Azurengine SDK release is not installed."
  exit 2
fi

version="$(sed -nE 's/.*Version:[[:space:]]*([0-9]+(\.[0-9]+)+).*/\1/p' "$CREATION_TIMESTAMP" | sed -n '1p')"
if [[ -n "$version" ]]; then
  echo "$version"
  exit 0
fi

echo "0.0.0.1"
exit 1
