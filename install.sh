#!/usr/bin/env bash
set -Eeuo pipefail

readonly PRODUCT_NAME="XDL SDK"
readonly SDK_VERSION="1.6.7.2"
readonly X86_FILE="xdl_sdk_1.6.7.2_x86_64_debian.run"
readonly X86_URL="https://github.com/xdltek/xdl-sdk/releases/download/v1.6.7.2/${X86_FILE}"
readonly X86_SHA256="9e520353f391176ea4eb6de8219b11e16339b1b045dd7c7c73245a32d01b2d95"
readonly X86_SIZE="240863938"
readonly ARM_FILE="xdl_sdk_1.6.7.2_aarch64_debian.run"
readonly ARM_URL="https://github.com/xdltek/xdl-sdk/releases/download/v1.6.7.2/${ARM_FILE}"
readonly ARM_SHA256="a4ff9d0b9da433870752a964d667139ac1dea5d8f5ba0bfd6951070934ddf724"
readonly ARM_SIZE="241186978"
readonly MIN_EXTRA_BYTES=$((512 * 1024 * 1024))

DOWNLOAD_DIR="${DOWNLOAD_DIR:-$(pwd)/downloads}"
SELECTED_ARCH=""
ASSUME_YES=0
CHECK_ONLY=0
DOWNLOAD_ONLY=0
USE_COLOR=1
FAILED_CHECKS=0
PACKAGE_DB_BROKEN=0
DISK_SPACE_FAILED=0
ARTIFACT_BLOCKED=0
CURL_UNAVAILABLE=0

if [[ ! -t 1 || -n "${NO_COLOR:-}" ]]; then
  USE_COLOR=0
fi

if [[ "$USE_COLOR" -eq 1 ]]; then
  C_BLUE=$'\033[1;34m'
  C_GREEN=$'\033[1;32m'
  C_YELLOW=$'\033[1;33m'
  C_RED=$'\033[1;31m'
  C_BOLD=$'\033[1m'
  C_RESET=$'\033[0m'
else
  C_BLUE="" C_GREEN="" C_YELLOW="" C_RED="" C_BOLD="" C_RESET=""
fi

usage() {
  cat <<EOF
${PRODUCT_NAME} ${SDK_VERSION} Installer

Usage:
  bash install.sh [options]

Options:
  --arch x86_64|aarch64  Select SDK architecture (default: detect host)
  --check-only            Print the complete readiness report; change nothing
  --download-only         Check, verify, and download without installing
  --download-dir DIR      Store the installer in DIR (default: ./downloads)
  -y, --yes               Approve dependency and SDK installation prompts
  --no-color              Disable ANSI colors
  -h, --help              Show this help

Examples:
  bash install.sh --check-only
  bash install.sh
  bash install.sh --arch aarch64
  bash install.sh --download-only
  bash install.sh --yes
EOF
}

banner() {
  printf '\n%s' "$C_BLUE"
  printf '%s\n' '============================================================'
  printf '  %s %s\n' "$PRODUCT_NAME" "$SDK_VERSION"
  printf '  Professional installer for Ubuntu / Debian\n'
  printf '%s%s\n\n' '============================================================' "$C_RESET"
}

section() {
  printf '\n%s[%s]%s %s\n' "$C_BLUE" "$1" "$C_RESET" "$2"
}

info() { printf '%sINFO%s  %s\n' "$C_BLUE" "$C_RESET" "$*"; }
warn() { printf '%sWARN%s  %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
success() { printf '%sOK%s    %s\n' "$C_GREEN" "$C_RESET" "$*"; }

fail() {
  printf '%sERROR%s %s\n' "$C_RED" "$C_RESET" "$*" >&2
  exit 1
}

status_row() {
  local item="$1" status="$2" details="$3" color="$C_GREEN"
  case "$status" in
    MISSING|FAILED|BLOCKED) color="$C_RED" ;;
    WARNING|SKIPPED|WAITING) color="$C_YELLOW" ;;
  esac
  printf '  %-42s %s%-10s%s %s\n' "$item" "$color" "$status" "$C_RESET" "$details"
}

normalize_arch() {
  case "$1" in
    amd64|x86_64) printf 'x86_64' ;;
    arm64|aarch64) printf 'aarch64' ;;
    *) printf '%s' "$1" ;;
  esac
}

human_bytes() {
  awk -v bytes="$1" 'BEGIN {printf "%.1f GiB", bytes / 1073741824}'
}

run_as_root() {
  if [[ "$EUID" -eq 0 ]]; then
    "$@"
  else
    command -v sudo >/dev/null || fail "sudo is required for this operation"
    sudo "$@"
  fi
}

package_status() {
  dpkg-query -W -f='${db:Status-Abbrev}' "$1" 2>/dev/null || true
}

package_installed() {
  [[ "$(package_status "$1")" == "ii " ]]
}

artifact_reachable() {
  curl --fail --location --silent --head --connect-timeout 10 --max-time 30 \
    "$SDK_URL" >/dev/null 2>&1 && return 0
  curl --fail --location --silent --connect-timeout 10 --max-time 30 \
    --range 0-0 --max-filesize 1048576 --output /dev/null "$SDK_URL" 2>/dev/null
}

parse_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --arch)
        [[ $# -ge 2 ]] || fail "--arch requires a value"
        SELECTED_ARCH="$(normalize_arch "$2")"
        shift 2
        ;;
      --check-only) CHECK_ONLY=1; shift ;;
      --download-only) DOWNLOAD_ONLY=1; shift ;;
      --download-dir)
        [[ $# -ge 2 ]] || fail "--download-dir requires a value"
        DOWNLOAD_DIR="$2"
        shift 2
        ;;
      -y|--yes) ASSUME_YES=1; shift ;;
      --no-color)
        USE_COLOR=0
        C_BLUE="" C_GREEN="" C_YELLOW="" C_RED="" C_BOLD="" C_RESET=""
        shift
        ;;
      -h|--help) usage; exit 0 ;;
      *) fail "unknown option: $1 (use --help)" ;;
    esac
  done
  if [[ "$CHECK_ONLY" -eq 1 && "$DOWNLOAD_ONLY" -eq 1 ]]; then
    fail "--check-only and --download-only cannot be used together"
  fi
}

select_artifact() {
  [[ -n "$SELECTED_ARCH" ]] || SELECTED_ARCH="$(normalize_arch "$(uname -m)")"
  case "$SELECTED_ARCH" in
    x86_64)
      SDK_URL="$X86_URL" SDK_FILE="$X86_FILE" SDK_SHA256="$X86_SHA256" SDK_SIZE="$X86_SIZE"
      ;;
    aarch64)
      SDK_URL="$ARM_URL" SDK_FILE="$ARM_FILE" SDK_SHA256="$ARM_SHA256" SDK_SIZE="$ARM_SIZE"
      ;;
    *) fail "unsupported architecture '$SELECTED_ARCH'; choose x86_64 or aarch64" ;;
  esac
}

inspect_system() {
  section "1/5" "System compatibility"
  printf '  %-42s %-10s %s\n' "CHECK" "STATUS" "DETAILS"

  if [[ ! -r /etc/os-release ]]; then
    status_row "Operating system" "FAILED" "/etc/os-release is unavailable"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    return
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  OS_NAME="${PRETTY_NAME:-${ID:-unknown}}"
  case "${ID:-}" in
    ubuntu|debian) status_row "Operating system" "OK" "$OS_NAME" ;;
    *)
      status_row "Operating system" "FAILED" "$OS_NAME (Ubuntu/Debian required)"
      FAILED_CHECKS=$((FAILED_CHECKS + 1))
      ;;
  esac

  HOST_ARCH="$(normalize_arch "$(uname -m)")"
  if [[ "$HOST_ARCH" == "$SELECTED_ARCH" ]]; then
    status_row "CPU architecture" "OK" "$HOST_ARCH"
  elif [[ "$DOWNLOAD_ONLY" -eq 1 || "$CHECK_ONLY" -eq 1 ]]; then
    status_row "CPU architecture" "WARNING" "host=$HOST_ARCH, selected=$SELECTED_ARCH"
  else
    status_row "CPU architecture" "FAILED" "host=$HOST_ARCH, selected=$SELECTED_ARCH"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi

  status_row "Linux kernel" "OK" "$(uname -r)"

  if command -v dpkg-query >/dev/null && command -v apt-get >/dev/null; then
    status_row "Package manager" "OK" "APT / dpkg"
  else
    status_row "Package manager" "FAILED" "apt-get and dpkg-query are required"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi

  local audit_output=""
  if command -v dpkg >/dev/null; then
    audit_output="$(dpkg --audit 2>/dev/null || true)"
  fi
  if [[ -z "$audit_output" ]]; then
    status_row "Package database" "OK" "no incomplete packages detected"
  else
    status_row "Package database" "BLOCKED" "repair is required before installation"
    printf '%s\n' "$audit_output" | sed 's/^/      /'
    PACKAGE_DB_BROKEN=1
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi

  if [[ "$DOWNLOAD_ONLY" -eq 1 || "$CHECK_ONLY" -eq 1 ]]; then
    status_row "Administrator access" "SKIPPED" "not used in this mode"
  elif [[ "$EUID" -eq 0 ]]; then
    status_row "Administrator access" "OK" "running as root"
  elif command -v sudo >/dev/null; then
    status_row "Administrator access" "OK" "sudo is available"
  else
    status_row "Administrator access" "FAILED" "sudo or root access is required"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi
}

build_dependency_list() {
  DEP_NAMES=(curl ca-certificates coreutils libc6 libstdc++6 dctrl-tools build-essential)
  DEP_PURPOSES=(
    "secure SDK download"
    "TLS certificate validation"
    "file size and SHA-256 verification tools"
    "GNU C runtime library"
    "GNU C++ runtime library"
    "Debian package relationship tools"
    "compiler and build toolchain"
  )
  DEP_NAMES+=(dkms "linux-headers-$(uname -r)")
  DEP_PURPOSES+=("RPP kernel module management" "headers for the running kernel")
}

inspect_dependencies() {
  MISSING_PACKAGES=()
  section "2/5" "Required packages and libraries"
  printf '  %-42s %-10s %s\n' "PACKAGE / LIBRARY" "STATUS" "PURPOSE"
  local index package
  for index in "${!DEP_NAMES[@]}"; do
    package="${DEP_NAMES[$index]}"
    if package_installed "$package"; then
      status_row "$package" "OK" "${DEP_PURPOSES[$index]}"
    else
      status_row "$package" "MISSING" "${DEP_PURPOSES[$index]}"
      MISSING_PACKAGES+=("$package")
    fi
  done
}

install_missing_dependencies() {
  if (( ${#MISSING_PACKAGES[@]} == 0 )); then
    return 0
  fi

  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    FAILED_CHECKS=$((FAILED_CHECKS + ${#MISSING_PACKAGES[@]}))
    return
  fi

  warn "Missing required packages: ${MISSING_PACKAGES[*]}"
  if [[ "$ASSUME_YES" -eq 0 ]]; then
    read -r -p "Install the missing packages with APT now? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || fail "dependencies are not ready; installation cancelled"
  fi

  section "ACTION" "Installing prerequisites"
  run_as_root apt-get update
  run_as_root apt-get install -y "${MISSING_PACKAGES[@]}"

  local package
  for package in "${MISSING_PACKAGES[@]}"; do
    package_installed "$package" || fail "package '$package' is still not correctly installed"
  done
  success "All required packages are installed"
  inspect_dependencies
}

inspect_download_readiness() {
  section "3/5" "Download and storage readiness"
  printf '  %-42s %-10s %s\n' "CHECK" "STATUS" "DETAILS"

  local available required disk_path
  disk_path="$DOWNLOAD_DIR"
  if [[ "$CHECK_ONLY" -eq 0 ]]; then
    mkdir -p "$DOWNLOAD_DIR"
  else
    while [[ ! -e "$disk_path" && "$disk_path" != "/" ]]; do
      disk_path="$(dirname "$disk_path")"
    done
  fi
  available="$(df -PB1 "$disk_path" | awk 'NR==2 {print $4}')"
  required=$((SDK_SIZE + MIN_EXTRA_BYTES))
  if [[ "$available" =~ ^[0-9]+$ ]] && (( available >= required )); then
    status_row "Free disk space" "OK" "$(human_bytes "$available") available"
  else
    status_row "Free disk space" "FAILED" "$(human_bytes "${available:-0}") available; $(human_bytes "$required") required"
    DISK_SPACE_FAILED=1
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi

  if [[ -n "${https_proxy:-${HTTPS_PROXY:-}}" ]]; then
    status_row "HTTPS proxy" "OK" "configured"
  else
    status_row "HTTPS proxy" "SKIPPED" "direct connection"
  fi

  if ! package_installed curl || ! command -v curl >/dev/null; then
    status_row "Artifact server" "WAITING" "install curl, then check the SDK URL"
    CURL_UNAVAILABLE=1
  elif artifact_reachable; then
    status_row "Artifact server" "OK" "selected package is reachable"
  else
    status_row "Artifact server" "BLOCKED" "SDK URL is not reachable from this network"
    ARTIFACT_BLOCKED=1
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi

  status_row "Integrity metadata" "OK" "SHA-256 is published for this SDK package"
  status_row "Selected package" "OK" "$SDK_FILE"
}

print_plan() {
  local operation_mode="download and install"
  [[ "$DOWNLOAD_ONLY" -eq 1 ]] && operation_mode="download only"
  [[ "$CHECK_ONLY" -eq 1 ]] && operation_mode="readiness check only"
  section "4/5" "Installation plan"
  printf '  %-24s %s\n' "Product" "$PRODUCT_NAME"
  printf '  %-24s %s\n' "Version" "$SDK_VERSION"
  printf '  %-24s %s\n' "Operating system" "$OS_NAME"
  printf '  %-24s %s\n' "Architecture" "$SELECTED_ARCH"
  printf '  %-24s %s\n' "Package" "$SDK_FILE"
  printf '  %-24s %s\n' "Download directory" "$DOWNLOAD_DIR"
  printf '  %-24s %s\n' "Driver" "install (required)"
  printf '  %-24s %s\n' "Mode" "$operation_mode"
}

print_remediation() {
  section "NEXT" "How to resolve the failed checks"

  if [[ "$PACKAGE_DB_BROKEN" -eq 1 ]]; then
    printf '\n  Repair the Debian package database:\n\n'
    printf '    sudo apt --fix-broken install -y\n'
    printf '    sudo dpkg --configure -a\n'
  fi

  if (( ${#MISSING_PACKAGES[@]} > 0 )); then
    printf '\n  Install all missing packages:\n\n'
    printf '    sudo apt update\n'
    printf '    sudo apt install -y'
    printf ' %q' "${MISSING_PACKAGES[@]}"
    printf '\n'

    local missing_package
    for missing_package in "${MISSING_PACKAGES[@]}"; do
      if [[ "$SELECTED_ARCH" == "aarch64" && "$missing_package" == linux-headers-* ]]; then
        printf '\n  ARM vendor-kernel note:\n'
        printf '  If APT cannot locate %s, obtain headers that exactly match\n' "$missing_package"
        printf '  the board image and uname -r from the board vendor or XDL Technical Support.\n'
        break
      fi
    done
  elif [[ "$CURL_UNAVAILABLE" -eq 1 ]]; then
    printf '\n  Restore the required download command:\n\n'
    printf '    sudo apt update\n'
    printf '    sudo apt install --reinstall -y curl\n'
  fi

  if [[ "$DISK_SPACE_FAILED" -eq 1 ]]; then
    printf '\n  Free disk space in or move the download directory: %s\n' "$DOWNLOAD_DIR"
    printf '  You can select another location with --download-dir.\n'
  fi

  if [[ "$ARTIFACT_BLOCKED" -eq 1 ]]; then
    printf '\n  Check HTTPS access, firewall/allowlist rules, and proxy settings for the SDK server.\n'
    printf '  If your network requires a proxy, configure https_proxy before running the check again.\n'
  fi

  printf '\n  Re-run the read-only assessment after completing the actions above:\n\n'
  printf '    bash install.sh --check-only\n\n'
}

confirm_plan() {
  [[ "$ASSUME_YES" -eq 1 ]] && return
  printf '\n%sAll prerequisite checks passed.%s\n' "$C_GREEN" "$C_RESET"
  read -r -p "Continue with this plan? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || fail "installation cancelled by user"
}

verify_installer() {
  local path="$1" actual_size actual_sha256
  [[ -s "$path" ]] || return 1
  actual_size="$(wc -c < "$path" | tr -d '[:space:]')"
  [[ "$actual_size" == "$SDK_SIZE" ]] || return 1
  actual_sha256="$(sha256sum "$path" | awk '{print $1}')"
  [[ "$actual_sha256" == "$SDK_SHA256" ]]
}

download_sdk() {
  SDK_PATH="$DOWNLOAD_DIR/$SDK_FILE"
  TEMP_PATH="$SDK_PATH.tmp"
  trap 'rm -f "${TEMP_PATH:-}"' EXIT

  section "5/5" "SDK package preparation"
  if verify_installer "$SDK_PATH"; then
    success "Using verified local package: $SDK_PATH"
    return
  fi

  if [[ -e "$SDK_PATH" ]]; then
    warn "Existing package is incomplete or failed integrity verification; downloading again"
  fi
  rm -f "$TEMP_PATH"

  info "Downloading $SDK_FILE"
  curl --fail --location --show-error --progress-bar --retry 3 --retry-delay 2 \
    --output "$TEMP_PATH" "$SDK_URL" || fail "SDK download failed"
  verify_installer "$TEMP_PATH" || fail "SDK package size or SHA-256 verification failed"
  mv -f "$TEMP_PATH" "$SDK_PATH"
  chmod +x "$SDK_PATH"
  success "Package download and integrity verification completed"
}

install_sdk() {
  local args=()
  [[ "$ASSUME_YES" -eq 1 ]] && args+=(-i -y)

  section "INSTALL" "Installing ${PRODUCT_NAME} ${SDK_VERSION}"
  run_as_root bash "$SDK_PATH" "${args[@]}"
  success "SDK installer completed"
}

post_install_guidance() {
  section "VERIFY" "Installation result and next steps"
  if [[ -r /usr/local/rpp/doc/creation_timestamp.txt ]]; then
    status_row "SDK installation record" "OK" "/usr/local/rpp/doc/creation_timestamp.txt"
    sed 's/^/      /' /usr/local/rpp/doc/creation_timestamp.txt
  else
    status_row "SDK installation record" "WARNING" "creation timestamp was not found"
  fi

  local package_count
  package_count="$(dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\n' 2>/dev/null | awk '$1 == "ii" && $2 ~ /(rpp|azurengine|xdl)/ {count++} END {print count+0}')"
  if (( package_count > 0 )); then
    status_row "Installed SDK packages" "OK" "$package_count package(s) detected"
  else
    status_row "Installed SDK packages" "WARNING" "no matching dpkg package was detected"
  fi

  printf '\n  Next steps:\n'
  printf '    1. Review packages: dpkg -l | grep -Ei "rpp|azurengine|xdl"\n'
  printf '    2. Reboot the host so the DKMS driver can load automatically.\n'
  printf '    3. After reboot, run: ae-smi\n'
  printf '    4. Uninstall with: sudo bash /usr/local/rpp/doc/uninstall.sh\n\n'
}

main() {
  parse_options "$@"
  select_artifact
  banner
  info "SDK installation starts only after every readiness check passes."
  info "Run with --check-only for a read-only assessment."

  inspect_system
  build_dependency_list
  inspect_dependencies

  if (( FAILED_CHECKS > 0 )); then
    print_remediation
    fail "$FAILED_CHECKS system compatibility check(s) failed; resolve them before installation"
  fi

  install_missing_dependencies
  inspect_download_readiness
  print_plan

  if (( FAILED_CHECKS > 0 )); then
    print_remediation
    fail "$FAILED_CHECKS readiness check(s) failed; no SDK installation was started"
  fi

  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    success "This host is ready for ${PRODUCT_NAME} ${SDK_VERSION}"
    exit 0
  fi

  confirm_plan
  download_sdk
  if [[ "$DOWNLOAD_ONLY" -eq 1 ]]; then
    success "Download-only operation completed: $SDK_PATH"
    exit 0
  fi

  install_sdk
  post_install_guidance
}

main "$@"
