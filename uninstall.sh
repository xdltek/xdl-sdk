#!/usr/bin/env bash
set -Eeuo pipefail

readonly PRODUCT_NAME="XDL SDK"
readonly SDK_VERSION="1.6.11"
readonly SDK_RECORD_FILE="${XDL_SDK_RECORD_FILE:-/usr/local/rpp/doc/creation_timestamp.txt}"
readonly SDK_UNINSTALL_SCRIPT="${XDL_SDK_UNINSTALL_SCRIPT:-/usr/local/rpp/doc/uninstall.sh}"

ASSUME_YES=0
USE_COLOR=1
SDK_PACKAGES=()

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
${PRODUCT_NAME} Uninstaller

Usage:
  bash uninstall.sh [options]

Options:
  -y, --yes    Confirm uninstall without prompting
  --no-color   Disable ANSI colors
  -h, --help   Show this help
EOF
}

section() { printf '\n%s[%s]%s %s\n' "$C_BLUE" "$1" "$C_RESET" "$2"; }
info() { printf '%sINFO%s  %s\n' "$C_BLUE" "$C_RESET" "$*"; }
warn() { printf '%sWARN%s  %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
success() { printf '%sOK%s    %s\n' "$C_GREEN" "$C_RESET" "$*"; }
fail() { printf '%sERROR%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

run_as_root() {
  if [[ "$EUID" -eq 0 ]]; then
    "$@"
  else
    command -v sudo >/dev/null || fail "sudo or root access is required"
    sudo "$@"
  fi
}

installed_sdk_packages() {
  { dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\n' 2>/dev/null || true; } |
    awk '
      ($1 == "ii" || $1 == "rc") {
        package=$2
        sub(/:.*/, "", package)
        if (package ~ /^(azurengine-|xdl-|rpp-)/) print package
      }
    ' | sort -u
}

collect_sdk_packages() {
  SDK_PACKAGES=()
  mapfile -t SDK_PACKAGES < <(installed_sdk_packages)
}

parse_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
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
}

print_plan() {
  section "PLAN" "Remove ${PRODUCT_NAME}"
  printf '  %-24s %s\n' "Product" "${PRODUCT_NAME} ${SDK_VERSION}"
  if [[ -f "$SDK_UNINSTALL_SCRIPT" ]]; then
    printf '  %-24s %s\n' "SDK uninstaller" "ready"
  else
    printf '  %-24s %s\n' "SDK uninstaller" "not present"
  fi
  printf '  %-24s %s\n' "Installed components" "${#SDK_PACKAGES[@]} detected"
}

format_uninstall_output() {
  local line package
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue
    case "$line" in
      *"apt does not have a stable CLI interface"*|Skip\ Debian\ package*|*"files and directories currently installed."*|"Processing triggers for libc-bin"*|正在处理用于\ libc-bin*)
        ;;
      "removing Debian package "*)
        package="${line#removing Debian package }"
        package="${package%%,*}"
        info "Removing $package"
        ;;
      *"Uninstall Beginning"*)
        info "Removing the XDL device driver..."
        ;;
      "DKMS: uninstall completed.")
        success "Device driver removed"
        ;;
      "Azurengine SDK uninstalled successfully"*)
        success "Main SDK components removed"
        ;;
      已删除*|*"not a symbolic link"*|*不是符号链接*|*"directory '/usr/local/rpp' not empty so not removed"*)
        ;;
      *[Ee][Rr][Rr][Oo][Rr]*|*失败*|*错误*)
        printf '%s%s%s\n' "$C_RED" "$line" "$C_RESET"
        ;;
      *[Ww][Aa][Rr][Nn][Ii][Nn][Gg]*|*警告*)
        printf '%s%s%s\n' "$C_YELLOW" "$line" "$C_RESET"
        ;;
      *)
        printf '%s\n' "$line"
        ;;
    esac
  done
}

run_uninstall_command() {
  local command_status log_status
  set +e
  run_as_root "$@" 2>&1 | tee -a "$UNINSTALL_LOG" | format_uninstall_output
  local pipeline_status=("${PIPESTATUS[@]}")
  set -e
  command_status="${pipeline_status[0]}"
  log_status="${pipeline_status[1]}"
  [[ "$log_status" -eq 0 ]] || warn "The removal continued, but the support log could not be saved completely."
  return "$command_status"
}

main() {
  parse_options "$@"
  collect_sdk_packages

  printf '\n%s============================================================%s\n' "$C_BLUE" "$C_RESET"
  printf '  %s %s — Easy removal\n' "$PRODUCT_NAME" "$SDK_VERSION"
  printf '%s============================================================%s\n' "$C_BLUE" "$C_RESET"

  if [[ ! -e "$SDK_RECORD_FILE" && ! -e "$SDK_UNINSTALL_SCRIPT" && ${#SDK_PACKAGES[@]} -eq 0 ]]; then
    success "No installed SDK or package remnants were detected; no action is required."
    exit 0
  fi

  print_plan
  warn "Close applications that are using XDL SDK before continuing."
  if [[ "$ASSUME_YES" -eq 0 ]]; then
    read -r -p "Uninstall the SDK and clean all detected remnants? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || fail "uninstall cancelled; the system was not changed"
  fi

  local log_dir="${UNINSTALL_LOG_DIR:-$(pwd)/downloads}"
  mkdir -p "$log_dir"
  UNINSTALL_LOG="$log_dir/uninstall-$(date '+%Y%m%d-%H%M%S').log"
  info "A complete removal log will be saved to: $UNINSTALL_LOG"

  if [[ -f "$SDK_UNINSTALL_SCRIPT" ]]; then
    section "STEP 1/3" "Removing XDL SDK"
    info "Removing SDK software and the device driver. This may take a few minutes."
    run_uninstall_command bash "$SDK_UNINSTALL_SCRIPT" || fail "XDL SDK removal did not complete. Review the error above or share this log with XDL Support: $UNINSTALL_LOG"
    success "XDL SDK removal step completed"
  else
    section "STEP 1/3" "Removing XDL SDK"
    warn "The main removal tool is unavailable; continuing with the detected SDK components."
  fi

  section "STEP 2/3" "Cleaning remaining components"
  collect_sdk_packages
  if (( ${#SDK_PACKAGES[@]} > 0 )); then
    info "Cleaning ${#SDK_PACKAGES[@]} remaining component(s)..."
    run_uninstall_command apt-get purge -y "${SDK_PACKAGES[@]}" || fail "Some SDK components could not be removed. Share this log with XDL Support: $UNINSTALL_LOG"
    success "Remaining SDK components were removed"
  else
    success "No remaining components need cleanup"
  fi

  section "STEP 3/3" "Confirming removal"
  collect_sdk_packages
  (( ${#SDK_PACKAGES[@]} == 0 )) || fail "SDK package remnants remain: ${SDK_PACKAGES[*]}"
  [[ ! -e "$SDK_RECORD_FILE" ]] || fail "SDK installation record remains: $SDK_RECORD_FILE"
  [[ ! -e "$SDK_UNINSTALL_SCRIPT" ]] || fail "SDK uninstaller remains: $SDK_UNINSTALL_SCRIPT"
  success "No XDL SDK components remain"
  printf '\n%s%s' "$C_GREEN" "$C_BOLD"
  printf '%s\n' '============================================================'
  printf '  REMOVAL SUCCESSFUL — XDL SDK %s\n' "$SDK_VERSION"
  printf '%s%s\n' '============================================================' "$C_RESET"
  printf '  XDL SDK has been removed from this computer.\n'
  printf '  Removal log: %s\n\n' "$UNINSTALL_LOG"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
