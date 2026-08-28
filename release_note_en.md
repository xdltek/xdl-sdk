# XDL SDK Release Notes

This file lists the SDK versions available through this repository and their user-visible
differences. SDK installer binaries are downloaded from the release server and are not
stored in Git.

**Total SDK versions: 1**

| Version | Release status | Platforms | Architectures | Main differences |
| --- | --- | --- | --- | --- |
| 1.6.7.2 | Public download | Ubuntu/Debian | x86_64, aarch64 | Professional customer installer with installed-version detection, read-only readiness checks, dependency reporting, guarded upgrades, GitHub Release download, SHA-256 verification, and post-install guidance. |

## 1.6.7.2

### SDK packages

- x86_64: `xdl_sdk_1.6.7.2_x86_64_debian.run`
- aarch64: `xdl_sdk_1.6.7.2_aarch64_debian.run`

### Installation behavior

- Detects the host architecture or accepts `--arch x86_64|aarch64`.
- Supports Ubuntu and Debian package-based systems.
- Prints a separate installed-version precheck before the five-stage workflow. Compatibility,
  dependencies, download readiness, the installation plan, and package preparation appear
  only when work must continue.
- Checks `curl`, `ca-certificates`, `coreutils`, `libc6`, `libstdc++6`, `dctrl-tools`,
  `build-essential`, `dkms`, and matching kernel headers before installation.
- Stops if the Debian package database contains incomplete or broken packages.
- Detects an existing SDK before download: the same version produces a final no-action-required
  result plus an emphasized optional two-step reinstall path and uninstall-completion warning;
  synchronously uninstalls
  and verifies removal of an older version after confirmation; blocks overwrite when the
  installed version is newer or unknown and prints the manual uninstall procedure.
- Lists exact SDK package or `rc` configuration remnants left after uninstall. A normal
  installation cleans and verifies them after confirmation, `--yes` confirms automatically,
  and `--check-only` prints the exact cleanup command without changing the host.
- Adds the one-command `bash uninstall.sh` entry point, which runs the bundled SDK uninstaller,
  cleans remaining packages, and verifies complete removal in sequence. `--yes` supports
  unattended confirmation.
- Checks free disk space, proxy configuration, and artifact-server reachability.
- Prefers a local package under `downloads/` or `--download-dir` after size and SHA-256
  verification. A valid local package skips `curl`, proxy, and artifact-server checks for
  one-command offline installation.
- Includes a ready-to-use `downloads/` directory by default. Its local `.gitignore` prevents
  SDK packages, temporary files, and other local content from being committed accidentally.
- Verifies the selected installer's published byte size and SHA-256 before execution.
- Supports `--check-only`, `--yes`, `--download-only`, `--download-dir`, and `--no-color`.
  The current SDK does not support skipping driver installation.
- Prints installation-result checks and clear reboot, device-verification, and uninstall steps.
- When read-only preflight detects missing packages, it prints copy-ready APT installation
  and recheck commands. Package-database, disk-space, and network failures also include
  targeted remediation guidance.
- Keeps downloaded `.run` packages outside Git under the ignored `downloads/` directory.

### Customer documentation

- Reworked the Chinese and English landing pages around customer outcomes, a three-step
  quick start, support scope, a prerequisite matrix, common deployment scenarios,
  post-install verification, troubleshooting, security, and support preparation.
- Clearly separates validated field evidence from compatibility claims that still require
  target-system validation.
- Added bilingual FAQ guidance for Debian package states, driver activation, manual module
  loading, MPS mode requests, uninstall residue, HTTP `403`, and kernel headers. MPS
  switching packages are not included in customer delivery and must be requested from
  XDL Technical Support.
- Added RK3588/ARM driver-build guidance for vendor kernel headers, a missing `python`
  command, and a missing `scripts/basic/fixdep`. Header packages must match the board image,
  running kernel, and architecture.
- Separated Chinese and English release notes so each README stays in one language.

### Validation status and known limitations

On 2026-08-26, both GitHub Release URLs passed anonymous Range requests, full downloads, and
SHA-256 verification. Installation and post-reboot validation passed on x86_64: `ae-smi`
detected an RPP_R9 device in the `WORKING` state. Installation and driver loading on an
aarch64 target, plus uninstall validation on both architectures, remain outstanding.
