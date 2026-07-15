#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/logger.sh
. "$SCRIPT_DIR/logger.sh"
# shellcheck source=scripts/utils.sh
. "$SCRIPT_DIR/utils.sh"

MIN_FREE_BYTES="${MIN_FREE_BYTES:-2147483648}"

check_root() {
  require_root
  log_info "Root permission check passed."
}

check_commands() {
  require_command python3
  require_command md5sum
  require_command df
  require_command awk
  require_command chmod

  if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
    log_error "Missing downloader: install wget or curl."
    exit 1
  fi

  log_info "Required command check passed."
}

check_network() {
  local url="${NETWORK_CHECK_URL:-https://github.com}"
  if command -v wget >/dev/null 2>&1; then
    wget --spider -q --timeout=10 "$url" || {
      log_error "Network check failed: $url"
      exit 1
    }
  else
    curl -fsI --connect-timeout 10 "$url" >/dev/null || {
      log_error "Network check failed: $url"
      exit 1
    }
  fi

  log_info "Network check passed."
}

check_disk() {
  local free_bytes
  free_bytes="$(free_bytes_for_path "${DOWNLOAD_DIR:-/tmp}")"
  if (( free_bytes < MIN_FREE_BYTES )); then
    log_error "Insufficient disk space. Need at least $MIN_FREE_BYTES bytes, available $free_bytes bytes."
    exit 1
  fi

  log_info "Disk space check passed."
}

check_os() {
  local os_id arch
  os_id="$(detect_os_id)"
  arch="$(detect_arch)"

  case "$os_id" in
    ubuntu|debian|kylin|openeuler)
      ;;
    *)
      log_error "Unsupported OS: $os_id"
      exit 1
      ;;
  esac

  case "$arch" in
    x86_64|aarch64)
      ;;
    *)
      log_error "Unsupported architecture: $arch"
      exit 1
      ;;
  esac

  log_info "OS check passed: $os_id/$arch"
}

check_root
check_commands
check_network
check_disk
check_os
