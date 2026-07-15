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

print_dependency_help() {
  local os_id="$1"

  log_error "Missing required SDK installation dependencies."
  case "$os_id" in
    openeuler)
      cat >&2 <<'EOF'

Install required packages on openEuler:

  sudo dnf install -y cmake
  sudo dnf install -y dkms

EOF
      ;;
    ubuntu|debian|kylin)
      cat >&2 <<'EOF'

Install required packages on Debian/Ubuntu/Kylin:

  sudo apt update
  sudo apt install -y cmake
  sudo apt install -y dkms dctrl-tools build-essential linux-headers-$(uname -r)

If rpp-dkms was left in a half-installed state, repair it first:

  sudo apt --fix-broken install -y
  sudo dpkg --configure -a

EOF
      ;;
  esac
}

check_sdk_dependencies() {
  local os_id="$1"
  local missing=()

  add_missing_dep() {
    local dep="$1"
    local item
    for item in "${missing[@]}"; do
      [[ "$item" == "$dep" ]] && return
    done
    missing+=("$dep")
  }

  command -v cmake >/dev/null 2>&1 || add_missing_dep "cmake"
  command -v dkms >/dev/null 2>&1 || add_missing_dep "dkms"

  case "$os_id" in
    ubuntu|debian|kylin)
      command -v grep-dctrl >/dev/null 2>&1 || add_missing_dep "dctrl-tools"
      command -v gcc >/dev/null 2>&1 || add_missing_dep "build-essential"
      command -v make >/dev/null 2>&1 || add_missing_dep "build-essential"
      [[ -d "/lib/modules/$(uname -r)/build" ]] || add_missing_dep "linux-headers-$(uname -r)"
      ;;
  esac

  if (( ${#missing[@]} > 0 )); then
    log_error "Missing dependencies: ${missing[*]}"
    print_dependency_help "$os_id"
    exit 1
  fi

  log_info "SDK dependency check passed."
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
  DETECTED_OS_ID="$os_id"
}

check_root
check_commands
check_network
check_disk
check_os
check_sdk_dependencies "$DETECTED_OS_ID"
