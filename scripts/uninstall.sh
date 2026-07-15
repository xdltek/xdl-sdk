#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNINSTALL_SCRIPT="/usr/local/rpp/doc/uninstall.sh"

# shellcheck source=utils.sh
. "$SCRIPT_DIR/utils.sh"

if [[ ! -f "$UNINSTALL_SCRIPT" ]]; then
  echo "Uninstall script not found: $UNINSTALL_SCRIPT" >&2
  echo "The Azurengine SDK release may not be installed." >&2
  exit 2
fi

bash "$UNINSTALL_SCRIPT"

os_id="$(detect_os_id)"
residual_packages=""

case "$os_id" in
  ubuntu|debian|kylin)
    if command -v dpkg >/dev/null 2>&1; then
      residual_packages="$(dpkg -l | grep -Ei "rpp|azurengine|xdl" || true)"
    fi
    ;;
  openeuler)
    if command -v rpm >/dev/null 2>&1; then
      residual_packages="$(rpm -qa | grep -Ei "rpp|azurengine|xdl" || true)"
    fi
    ;;
  *)
    if command -v rpm >/dev/null 2>&1; then
      residual_packages="$(rpm -qa | grep -Ei "rpp|azurengine|xdl" || true)"
    elif command -v dpkg >/dev/null 2>&1; then
      residual_packages="$(dpkg -l | grep -Ei "rpp|azurengine|xdl" || true)"
    fi
    ;;
esac

if [[ -z "$residual_packages" ]]; then
  echo "SDK uninstall verification passed. No residual RPP/Azurengine/XDL packages found."
  exit 0
fi

echo "SDK uninstall verification failed. Residual packages were found:" >&2
printf '%s\n' "$residual_packages" >&2
echo >&2
echo "Stop rpp_server or other RPP-related processes, then remove the residual packages." >&2

case "$os_id" in
  ubuntu|debian|kylin)
    echo "Suggested cleanup command:" >&2
    echo "  sudo apt purge -y azurengine-rpp-system-config rpp-dkms azurengine-rpp-drv-api-mps-off" >&2
    echo "  sudo apt autoremove -y" >&2
    ;;
  openeuler)
    residual_names="$(printf '%s\n' "$residual_packages" | tr '\n' ' ')"
    if command -v dnf >/dev/null 2>&1; then
      echo "Suggested cleanup command:" >&2
      echo "  sudo dnf remove -y $residual_names" >&2
    else
      echo "Suggested cleanup command:" >&2
      echo "  sudo rpm -e $residual_names" >&2
    fi
    ;;
  *)
    echo "Please remove the residual packages with the system package manager." >&2
    ;;
esac

exit 1
