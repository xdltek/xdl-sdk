#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  -h|--help|help)
    exec bash "$ROOT_DIR/sdk_manager.sh" help
    ;;
esac

bash "$ROOT_DIR/scripts/check_env.sh"
XDL_SDK_ENV_CHECKED=1 exec bash "$ROOT_DIR/sdk_manager.sh" install "$@"
