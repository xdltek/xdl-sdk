#!/usr/bin/env bash
set -euo pipefail

UNINSTALL_SCRIPT="/usr/local/rpp/doc/uninstall.sh"

if [[ ! -f "$UNINSTALL_SCRIPT" ]]; then
  echo "Uninstall script not found: $UNINSTALL_SCRIPT" >&2
  echo "The Azurengine SDK release may not be installed." >&2
  exit 2
fi

exec bash "$UNINSTALL_SCRIPT"
