<a id="english"></a>

<p align="center">
  <img src="images/logo_color_horizontal.png" width="320" alt="XDL logo">
</p>

<h1 align="center">XDL SDK</h1>

Language: [中文](README.md) | [English](README_EN.md)

## Overview

XDL SDK is the official SDK delivery portal for XDL customers, partners, and
solution teams. It provides a consistent, verified, and platform-aware way to
obtain XDL SDK releases and complete SDK lifecycle operations on supported
systems.

With this repository, users can install, update, verify, list, and uninstall XDL
SDK packages through a unified command-line experience. The package manager
automatically selects the correct SDK installer according to the target OS and
CPU architecture, downloads the release package from the official XDL artifact
source, verifies integrity with MD5, and executes the SDK installer.

## Key Capabilities

- One-command SDK installation with `install.sh`
- Full SDK lifecycle management with `sdk_manager.sh`
- Platform-aware SDK package selection through `sdk.json`
- Automatic download from the official XDL artifact source
- MD5 verification before installation
- Install, update, uninstall, list, verify, and version commands
- Environment and dependency checks before installation
- Rollback support for failed SDK updates

## Quick Start

```bash
git clone https://github.com/xdltek/xdl-sdk.git
cd xdl-sdk
sudo bash install.sh
```

Default flow:

1. Check root permission, network, downloader tools, disk space, OS, architecture, and SDK dependencies.
2. Read `sdk.json`.
3. Select the `latest` SDK version.
4. Detect the host OS and CPU architecture.
5. Download the matching SDK `.run` installer.
6. Verify MD5.
7. Run the SDK installer.
8. Cache the installer for rollback.

## Repository Layout

```text
xdl-sdk/
|-- install.sh
|-- sdk_manager.sh
|-- sdk.json
|-- README.md
|-- README_EN.md
|-- LICENSE
|-- images/
|   |-- logo_color_horizontal.png
|-- scripts/
|   |-- check_env.sh
|   |-- download.sh
|   |-- get_version.sh
|   |-- json_query.py
|   |-- logger.sh
|   |-- uninstall.sh
|   |-- upgrade.sh
|   |-- utils.sh
|   |-- verify_md5.sh
```

## File Roles

| File | Role |
| --- | --- |
| `install.sh` | Customer entry point. Performs environment checks, then starts SDK installation. |
| `sdk_manager.sh` | SDK package manager for install, update, uninstall, list, verify, and version operations. |
| `sdk.json` | SDK package index. Defines versions, supported OS/architecture combinations, download URLs, MD5 values, and release note links. |
| `README.md` | Chinese user guide and default GitHub entry page. |
| `scripts/json_query.py` | Internal JSON parser used by `sdk_manager.sh`; users do not need to call it directly. |
| `scripts/` | Internal helper scripts for environment checks, download, verification, logging, and compatibility wrappers. |
| `LICENSE` | Repository license. |

## Commands

Root permission is required only for commands that modify the host system:
`install`, `update`, and `uninstall`. Read-only commands such as `list`,
`verify`, and `version` do not require `sudo`.

Install latest SDK:

```bash
sudo bash install.sh
```

Install with package manager:

```bash
sudo bash sdk_manager.sh install
```

Install a specific SDK version:

```bash
sudo bash sdk_manager.sh install --version 1.6.7.2
```

Install without driver build/load:

```bash
sudo bash sdk_manager.sh install --skip-drv
```

Update SDK:

```bash
sudo bash sdk_manager.sh update
```

Uninstall SDK:

```bash
sudo bash sdk_manager.sh uninstall
```

List downloadable SDK packages:

```bash
bash sdk_manager.sh list
```

Verify package download and MD5:

```bash
bash sdk_manager.sh verify --version 1.6.7.2
```

Show installed SDK version:

```bash
bash sdk_manager.sh version
```

## Post-Installation Verification

After installation, confirm the SDK package installation and RPP driver status
with the system package manager and `ae-smi`.

### openEuler

Check installed XDL/RPP RPM packages:

```bash
rpm -qa | grep -Ei "rpp|azurengine|xdl"
```

Example output:

```text
rpp-dkms-2.0.16.3-1.noarch
azurengine-rpp-rpp-configuration-1-1.x86_64
azurengine-rpp-drv-api-1-1.x86_64
azurengine-ae-smi-1-1.x86_64
azurengine-rpp-tool-chain-rppblas-1-1.x86_64
azurengine-rpp-system-config-1-1.noarch
azurengine-rpp-tool-chain-main-1-1.x86_64
azurengine-rpp-perf-1-1.x86_64
azurengine-rpp-mpu-tools-1-1.x86_64
azurengine-rpp-tool-chain-rppfft-1-1.x86_64
```

To inspect a specific RPM package:

```bash
rpm -qi <pkg_name>
rpm -qi azurengine-rpp-drv-api-1-1.x86_64
```

### Debian / Ubuntu / Kylin

Check installed XDL/RPP DEB packages:

```bash
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

### RPP Driver Status

Use `ae-smi` to confirm whether the driver has taken effect. Press `q` to exit.

```bash
ae-smi
```

If `ae-smi` displays device information or the monitoring interface normally,
the RPP card and driver are working.

If the following warning appears, the driver or device has not taken effect:

```text
Warning: No devices initialized successfully. init false
Warning: ae-smi init false.
Warning: No DEV to monitor.
```

Recommended actions:

1. Reboot the machine. DKMS will load the kernel module automatically after reboot.
2. If reboot is not practical, load the driver manually:

```bash
cd /lib/modules/$(uname -r)/updates/dkms/
sudo xz -dk /lib/modules/$(uname -r)/updates/dkms/rpp.ko.xz
sudo insmod rpp.ko
sudo chmod 666 /dev/rpp0_entire_ctrl /dev/ve0_entire_ctrl
```

## Post-Uninstall Verification

After uninstall, `sdk_manager.sh uninstall` automatically checks for residual
XDL/RPP packages. If residual packages are found, the command returns an error
and prints a cleanup command for the detected platform.

Manual check on openEuler:

```bash
rpm -qa | grep -Ei "rpp|azurengine|xdl"
```

Manual check on Debian / Ubuntu / Kylin:

```bash
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

No output means the related packages have been removed. If residual packages
remain, first make sure `rpp_server` or other RPP-related processes are stopped.

openEuler cleanup example:

```bash
sudo dnf remove -y <residual_package_names>
```

Debian / Ubuntu / Kylin cleanup example:

```bash
sudo apt purge -y azurengine-rpp-system-config rpp-dkms azurengine-rpp-drv-api-mps-off
sudo apt autoremove -y
```

## Supported OS

Current `sdk.json` supports:

| OS | Architecture | Package mapping |
| --- | --- | --- |
| Ubuntu | `x86_64`, `aarch64` | Debian SDK package |
| Debian | `x86_64`, `aarch64` | Debian SDK package |
| Kylin | `x86_64`, `aarch64` | Debian SDK package |
| openEuler | `x86_64` | openEuler SDK package |

Use overrides only when auto-detection is not sufficient:

```bash
sudo bash sdk_manager.sh install --os ubuntu --arch x86_64
```

## Platform Requirements

### Installer Script Requirements

| Component | Requirement |
| --- | --- |
| Shell | Bash |
| Python | Python 3, recommended Python 3.11 |
| Downloader | `wget` or `curl` |
| Checksum tool | `md5sum` |
| Privilege | Root permission for install, update, and uninstall |

### Ubuntu

Supported platforms:

- x86_64 host
- RK3588
- RK3568

Minimum requirements:

| Component | Requirement |
| --- | --- |
| Operating System | Ubuntu 20.04 LTS or compatible Ubuntu-based distribution |
| System Memory | >= 16 GB DDR5 recommended |
| CPU Architecture | x86_64 or aarch64 |
| Compiler | GCC 9.4.0 or compatible |
| CMake | >= 3.26.5 recommended |
| Python | Python 3.11 recommended |
| Build Tools | `build-essential`, `linux-headers`, `dkms`, `dctrl-tools` |

### Kylin

Supported CPU platforms:

- Hygon
- Phytium

Validated kernel/compiler baseline:

```text
Linux version 5.4.18-152-generic
GCC 9.4.0 (Ubuntu 9.4.0-1ubuntu1~20.04.1)
```

Validated aarch64 kernel baseline:

```text
Linux version 6.6.0-58-generic #57-KYLINOS SMP Thu Dec 18 12:24:49 UTC 2025 aarch64
```

### openEuler

Supported platform:

- x86_64 host

Validated kernel/compiler baseline:

```text
Linux version 6.6.0-127.0.0.125.oe2403sp1.x86_64
GCC 12.3.1 (openEuler 12.3.1-65.oe2403sp1)
GNU Binutils 2.41
```

## SDK Package Index

SDK package selection is controlled by `sdk.json`. Future SDK releases should be
added by updating `sdk.json`; package URLs should not be hard-coded in shell
scripts.

Example structure:

```json
{
  "latest": "1.6.7.2",
  "sdk": {
    "1.6.7.2": {
      "packages": {
        "ubuntu": {
          "x86_64": {
            "file": "azurengine_sw_1.6.7.2_x86_64_debian.run",
            "url": "<official-artifact-url>",
            "md5": "741021ce9d34b1f6b8717c2900fa9fbb"
          }
        }
      }
    }
  }
}
```

## Troubleshooting

### Missing prerequisite packages

The SDK `.run` installer includes `rpp-dkms`. Driver installation depends on
system packages such as `dkms` and `cmake`. If these packages are missing,
`rpp-dkms` may stop in the `iU` half-installed state and package managers may
report broken dependencies.

`install.sh` and `sdk_manager.sh install/update` check these dependencies before
running the SDK installer. If any dependency is missing, the script prints the
required installation commands and exits before modifying the SDK installation.

#### Debian / Ubuntu / Kylin

```bash
sudo apt update
sudo apt install -y cmake
sudo apt install -y dkms dctrl-tools build-essential linux-headers-$(uname -r)
```

Confirm:

```bash
dpkg -l dkms dctrl-tools | grep ^ii
dkms --version
cmake --version
```

If a previous installation attempt left `rpp-dkms` in a half-installed state:

```bash
sudo apt --fix-broken install -y
sudo dpkg --configure -a
```

#### openEuler

```bash
sudo dnf install -y cmake
sudo dnf install -y dkms
```

Confirm:

```bash
dkms --version
cmake --version
```

## FAQ

### Where are SDK packages stored?

SDK `.run` packages are stored in the official XDL artifact release source, not
in this repository.

### What if MD5 verification fails?

Delete the downloaded file under `downloads/<version>/` and rerun the command.

### What if the OS is detected incorrectly?

Use `--os` and `--arch` overrides:

```bash
sudo bash sdk_manager.sh install --os ubuntu --arch x86_64
```

## Release Notes

- **Version 1.6.7.2** (2026-07-15): Initial public release of the XDL SDK
  delivery portal, including platform-aware package selection, MD5
  verification, install/update/uninstall workflows, dependency checks, and
  rollback support.

Release package files and package-level release notes are managed by XDL through
the official SDK artifact release source.

## Revision History

| Version | Date | Author | Description |
| --- | --- | --- | --- |
| 1.6.7.2 | 2026-07-15 | XDL Technical Support Team | Initial public SDK delivery release |

## License

This repository is licensed under the Apache License 2.0. See [LICENSE](LICENSE).
