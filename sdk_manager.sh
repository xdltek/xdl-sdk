#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$ROOT_DIR/scripts"
SDK_JSON="$ROOT_DIR/sdk.json"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$ROOT_DIR/downloads}"
CACHE_DIR="/var/cache/azurengine"
CACHE_RUN="$CACHE_DIR/sdk_release.run"
UNINSTALL_SCRIPT="/usr/local/rpp/doc/uninstall.sh"

# shellcheck source=scripts/logger.sh
. "$SCRIPT_DIR/logger.sh"
# shellcheck source=scripts/utils.sh
. "$SCRIPT_DIR/utils.sh"

usage() {
  cat <<'USAGE'
Usage:
  bash sdk_manager.sh <command> [options]

Commands:
  install                  Download, verify, and install an SDK package.
  update                   Download, verify, update SDK, and roll back on failure.
  uninstall                Uninstall the installed SDK.
  list                     List downloadable SDK packages from sdk.json.
  verify                   Download if needed, then verify the SDK package MD5.
  version                  Show installed SDK version on this host.
  help                     Show this help.

Common options:
  --version <version>      SDK version to use. Default: latest in sdk.json.
  --os <os>                Override OS selection. Supported: ubuntu, debian, uos, openeuler.
  --arch <arch>            Override architecture selection. Supported: x86_64, aarch64.
  --download-dir <dir>     Package download directory. Default: ./downloads.
  --skip-drv               Pass --skip-drv to the SDK .run installer.
  -h, --help               Show this help.

Examples:
  bash install.sh
  bash sdk_manager.sh install
  bash sdk_manager.sh install --version 1.6.7.2 --os ubuntu --arch x86_64
  bash sdk_manager.sh update --skip-drv
  bash sdk_manager.sh list
  bash sdk_manager.sh verify --version 1.6.7.2
  bash sdk_manager.sh uninstall
  bash sdk_manager.sh version
USAGE
}

require_json_tools() {
  require_command python3
  require_command md5sum
  require_command chmod
}

latest_version() {
  python3 "$SCRIPT_DIR/json_query.py" latest "$SDK_JSON"
}

list_packages() {
  python3 "$SCRIPT_DIR/json_query.py" list "$SDK_JSON" |
    awk 'BEGIN {printf "%-10s %-12s %-10s %-55s %s\n", "VERSION", "OS", "ARCH", "FILE", "MD5"} {printf "%-10s %-12s %-10s %-55s %s\n", $1, $2, $3, $4, $5}'
}

parse_common_options() {
  SELECTED_VERSION="latest"
  SELECTED_OS="$(detect_os_id)"
  SELECTED_ARCH="$(detect_arch)"
  SKIP_DRV=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version)
        [[ $# -ge 2 ]] || { log_error "--version requires a value"; exit 2; }
        SELECTED_VERSION="$2"
        shift 2
        ;;
      --os)
        [[ $# -ge 2 ]] || { log_error "--os requires a value"; exit 2; }
        SELECTED_OS="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"
        [[ "$SELECTED_OS" == "open_euler" ]] && SELECTED_OS="openeuler"
        shift 2
        ;;
      --arch)
        [[ $# -ge 2 ]] || { log_error "--arch requires a value"; exit 2; }
        SELECTED_ARCH="$2"
        [[ "$SELECTED_ARCH" == "amd64" ]] && SELECTED_ARCH="x86_64"
        [[ "$SELECTED_ARCH" == "arm64" ]] && SELECTED_ARCH="aarch64"
        shift 2
        ;;
      --download-dir)
        [[ $# -ge 2 ]] || { log_error "--download-dir requires a value"; exit 2; }
        DOWNLOAD_DIR="$2"
        shift 2
        ;;
      --skip-drv)
        SKIP_DRV=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage >&2
        exit 2
        ;;
    esac
  done
}

resolve_package() {
  PACKAGE_VERSION=""
  PACKAGE_OS=""
  PACKAGE_ARCH=""
  PACKAGE_FILE=""
  PACKAGE_URL=""
  PACKAGE_MD5=""
  PACKAGE_SIZE_BYTES=0
  PACKAGE_RELEASE_NOTES=""

  local line key value
  while IFS=$'\t' read -r key value; do
    case "$key" in
      version) PACKAGE_VERSION="$value" ;;
      os) PACKAGE_OS="$value" ;;
      arch) PACKAGE_ARCH="$value" ;;
      file) PACKAGE_FILE="$value" ;;
      url) PACKAGE_URL="$value" ;;
      md5) PACKAGE_MD5="$value" ;;
      size_bytes) PACKAGE_SIZE_BYTES="${value:-0}" ;;
      release_notes) PACKAGE_RELEASE_NOTES="$value" ;;
    esac
  done < <(python3 "$SCRIPT_DIR/json_query.py" resolve "$SDK_JSON" "$SELECTED_VERSION" "$SELECTED_OS" "$SELECTED_ARCH")

  PACKAGE_DIR="$DOWNLOAD_DIR/$PACKAGE_VERSION"
  PACKAGE_PATH="$PACKAGE_DIR/$PACKAGE_FILE"
}

check_disk_for_package() {
  mkdir -p "$PACKAGE_DIR"

  local required available
  required=$(( PACKAGE_SIZE_BYTES + 1073741824 ))
  available="$(free_bytes_for_path "$PACKAGE_DIR")"

  if (( PACKAGE_SIZE_BYTES > 0 && available < required )); then
    log_error "Insufficient disk space in $PACKAGE_DIR. Need $required bytes, available $available bytes."
    exit 1
  fi
}

download_package_if_needed() {
  if [[ -f "$PACKAGE_PATH" ]]; then
    if bash "$SCRIPT_DIR/verify_md5.sh" "$PACKAGE_PATH" "$PACKAGE_MD5" >/dev/null 2>&1; then
      log_info "Using existing verified package: $PACKAGE_PATH"
      return
    fi
    log_warn "Existing package failed MD5 verification. Re-downloading: $PACKAGE_PATH"
    rm -f "$PACKAGE_PATH"
  fi

  check_disk_for_package
  log_info "Downloading SDK $PACKAGE_VERSION for $PACKAGE_OS/$PACKAGE_ARCH"
  log_info "URL: $PACKAGE_URL"
  bash "$SCRIPT_DIR/download.sh" "$PACKAGE_URL" "$PACKAGE_PATH"
}

prepare_package() {
  require_json_tools
  resolve_package
  download_package_if_needed
  bash "$SCRIPT_DIR/verify_md5.sh" "$PACKAGE_PATH" "$PACKAGE_MD5"
  chmod +x "$PACKAGE_PATH"
  log_info "Prepared package: $PACKAGE_PATH"
}

cache_package() {
  mkdir -p "$CACHE_DIR"
  cp -f "$PACKAGE_PATH" "$CACHE_RUN"
  log_info "Cached package: $CACHE_RUN"
}

installed_version() {
  bash "$SCRIPT_DIR/get_version.sh"
}

install_sdk() {
  parse_common_options "$@"
  require_root
  prepare_package

  local install_args=(-i -y)
  if [[ "$SKIP_DRV" -eq 1 ]]; then
    install_args+=(--skip-drv)
  fi

  log_info "Installing XDL SDK $PACKAGE_VERSION"
  bash "$PACKAGE_PATH" "${install_args[@]}"
  cache_package
}

uninstall_sdk() {
  require_root
  bash "$SCRIPT_DIR/uninstall.sh"
}

cleanup_backup() {
  local backup_dir="$1"
  if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
    rm -rf "$backup_dir"
  fi
}

update_sdk() {
  parse_common_options "$@"
  require_root
  prepare_package

  local backup_dir sdk_libraries_directory samples_directory
  backup_dir="$(mktemp -d -p /tmp azurengine_XXXXXX)"
  sdk_libraries_directory="/usr/local/rpp"
  samples_directory="$HOME/azurengine"
  log_info "Backup directory: $backup_dir"

  if [[ -d "$sdk_libraries_directory" ]]; then
    cp -a "$sdk_libraries_directory" "$backup_dir/"
  fi

  if [[ -d "$samples_directory" ]]; then
    cp -a "$samples_directory" "$backup_dir/"
  fi

  local install_args=(-i -y)
  if [[ "$SKIP_DRV" -eq 1 ]]; then
    install_args+=(--skip-drv)
  fi

  log_info "Updating XDL SDK to $PACKAGE_VERSION"
  set +e
  bash "$PACKAGE_PATH" "${install_args[@]}"
  local install_status=$?
  set -e

  if [[ "$install_status" -eq 12 ]]; then
    log_warn "Current package is not newer than the installed SDK."
    cleanup_backup "$backup_dir"
    return 12
  fi

  if [[ "$install_status" -ne 0 ]]; then
    log_error "Update failed. Rolling back to the previous SDK package."

    if [[ -f "$UNINSTALL_SCRIPT" ]]; then
      set +e
      bash "$UNINSTALL_SCRIPT"
      set -e
    fi

    rm -rf "$sdk_libraries_directory"
    rm -rf "$samples_directory"

    local rollback_status=1
    if [[ -f "$CACHE_RUN" ]]; then
      set +e
      bash "$CACHE_RUN" -i -y
      rollback_status=$?
      set -e
    else
      log_error "Cached rollback package not found: $CACHE_RUN"
    fi

    if [[ "$rollback_status" -ne 0 ]]; then
      log_error "Rollback install failed. Restoring backup files."
      if [[ -d "$backup_dir/rpp" ]]; then
        cp -rf "$backup_dir/rpp" "/usr/local/"
      fi
      if [[ -d "$backup_dir/azurengine" ]]; then
        cp -rf "$backup_dir/azurengine" "$HOME/"
      fi
      cleanup_backup "$backup_dir"
      return 11
    fi

    cleanup_backup "$backup_dir"
    return 10
  fi

  cache_package
  cleanup_backup "$backup_dir"
  log_info "Update completed."
}

verify_sdk() {
  parse_common_options "$@"
  prepare_package
}

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 0
  fi

  local command="$1"
  shift

  case "$command" in
    install|-i|--install)
      install_sdk "$@"
      ;;
    update|upgrade|-U|--update)
      update_sdk "$@"
      ;;
    uninstall|remove|-u|--uninstall)
      uninstall_sdk "$@"
      ;;
    list|ls)
      require_json_tools
      list_packages
      ;;
    verify|check)
      verify_sdk "$@"
      ;;
    version|-v|--version)
      installed_version
      ;;
    latest)
      require_json_tools
      latest_version
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      log_error "Unknown command: $command"
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
