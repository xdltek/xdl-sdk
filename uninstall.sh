#!/usr/bin/env bash
set -Eeuo pipefail

readonly PRODUCT_NAME="XDL SDK"
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
  C_RESET=$'\033[0m'
else
  C_BLUE="" C_GREEN="" C_YELLOW="" C_RED="" C_RESET=""
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
        C_BLUE="" C_GREEN="" C_YELLOW="" C_RED="" C_RESET=""
        shift
        ;;
      -h|--help) usage; exit 0 ;;
      *) fail "unknown option: $1 (use --help)" ;;
    esac
  done
}

print_plan() {
  local installed_version="unknown"
  if [[ -r "$SDK_RECORD_FILE" ]]; then
    installed_version="$(awk -F ':[[:space:]]*' '
      tolower($1) == "version" {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}
    ' "$SDK_RECORD_FILE")"
    [[ -n "$installed_version" ]] || installed_version="unknown"
  fi

  section "PLAN" "Uninstall ${PRODUCT_NAME}"
  printf '  %-24s %s\n' "Installed version" "$installed_version"
  if [[ -f "$SDK_UNINSTALL_SCRIPT" ]]; then
    printf '  %-24s %s\n' "SDK uninstaller" "ready"
  else
    printf '  %-24s %s\n' "SDK uninstaller" "not present"
  fi
  printf '  %-24s %s\n' "Package cleanup" "${#SDK_PACKAGES[@]} package(s) detected"
  if (( ${#SDK_PACKAGES[@]} > 0 )); then
    printf '    - %s\n' "${SDK_PACKAGES[@]}"
  fi
}

main() {
  parse_options "$@"
  collect_sdk_packages

  printf '\n%s============================================================%s\n' "$C_BLUE" "$C_RESET"
  printf '  %s — complete removal\n' "$PRODUCT_NAME"
  printf '%s============================================================%s\n' "$C_BLUE" "$C_RESET"

  if [[ ! -e "$SDK_RECORD_FILE" && ! -e "$SDK_UNINSTALL_SCRIPT" && ${#SDK_PACKAGES[@]} -eq 0 ]]; then
    success "No installed SDK or package remnants were detected; no action is required."
    exit 0
  fi

  print_plan
  warn "SDK services and applications must be stopped before uninstall."
  if [[ "$ASSUME_YES" -eq 0 ]]; then
    read -r -p "Uninstall the SDK and clean all detected remnants? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || fail "uninstall cancelled; the system was not changed"
  fi

  if [[ -f "$SDK_UNINSTALL_SCRIPT" ]]; then
    section "1/3" "Running the SDK uninstaller"
    info "Waiting for the SDK uninstaller to finish"
    run_as_root bash "$SDK_UNINSTALL_SCRIPT" || fail "SDK uninstaller failed; package cleanup was not started"
    success "SDK uninstaller completed"
  else
    section "1/3" "SDK uninstaller"
    warn "The SDK uninstaller is absent; continuing with detected package remnants"
  fi

  section "2/3" "Cleaning remaining SDK packages"
  collect_sdk_packages
  if (( ${#SDK_PACKAGES[@]} > 0 )); then
    printf '  Removing:\n'
    printf '    - %s\n' "${SDK_PACKAGES[@]}"
    run_as_root apt-get purge -y "${SDK_PACKAGES[@]}"
    success "Remaining SDK packages were cleaned"
  else
    success "No package remnants require cleanup"
  fi

  section "3/3" "Verifying complete removal"
  collect_sdk_packages
  (( ${#SDK_PACKAGES[@]} == 0 )) || fail "SDK package remnants remain: ${SDK_PACKAGES[*]}"
  [[ ! -e "$SDK_RECORD_FILE" ]] || fail "SDK installation record remains: $SDK_RECORD_FILE"
  [[ ! -e "$SDK_UNINSTALL_SCRIPT" ]] || fail "SDK uninstaller remains: $SDK_UNINSTALL_SCRIPT"
  success "${PRODUCT_NAME} and detected package remnants were removed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
