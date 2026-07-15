#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: bash verify_run_file.sh <run-file> <expected-md5>" >&2
  exit 2
fi

run_file="$1"
expected_md5="$2"

if [[ ! -f "$run_file" ]]; then
  echo "SDK package not found: $run_file" >&2
  exit 2
fi

actual_md5="$(md5sum "$run_file" | awk '{print $1}')"
if [[ "$actual_md5" != "$expected_md5" ]]; then
  echo "MD5 verification failed: $run_file" >&2
  echo "Expected: $expected_md5" >&2
  echo "Actual:   $actual_md5" >&2
  exit 1
fi

echo "MD5 verification passed: $run_file"
