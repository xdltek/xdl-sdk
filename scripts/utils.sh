#!/usr/bin/env bash

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

detect_os_id() {
  local os_id="unknown"
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    os_id="${ID:-unknown}"
  fi

  os_id="$(printf '%s' "$os_id" | tr '[:upper:]' '[:lower:]')"
  case "$os_id" in
    open_euler|openeuler)
      echo "openeuler"
      ;;
    uniontech|uos)
      echo "uos"
      ;;
    *)
      echo "$os_id"
      ;;
  esac
}

detect_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)
      echo "x86_64"
      ;;
    aarch64|arm64)
      echo "aarch64"
      ;;
    *)
      echo "$arch"
      ;;
  esac
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "This command must be run as root. Use sudo or log in as root." >&2
    exit 1
  fi
}

free_bytes_for_path() {
  local path="$1"
  df -PB1 "$path" | awk 'NR == 2 {print $4}'
}
