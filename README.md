<p align="center">
  <img src="images/logo_color_horizontal.png" width="320" alt="XDL logo">
</p>

<h1 align="center">XDL SDK</h1>

Customer-facing installer repository for downloading, verifying, installing,
updating, and uninstalling XDL SDK releases.

This repository does not store SDK installer packages. It reads package metadata
from `sdk.json` and downloads SDK artifacts from:

```text
https://github.com/xdltek/xdl-sdk-artifacts
```

## Quick Start

```bash
git clone https://github.com/xdltek/xdl-sdk.git
cd xdl-sdk
sudo bash install.sh
```

Default behavior:

1. Check root permission, network access, downloader tools, disk space, OS, architecture, and SDK installation dependencies.
2. Read `sdk.json`.
3. Select `latest`.
4. Detect the host OS and architecture.
5. Download the matching SDK `.run` installer from `xdl-sdk-artifacts`.
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
|-- VERSION
|-- LICENSE
|-- images/
|   `-- logo_color_horizontal.png
`-- scripts/
    |-- check_env.sh
    |-- download.sh
    |-- get_version.sh
    |-- json_query.py
    |-- logger.sh
    |-- uninstall.sh
    |-- upgrade.sh
    |-- utils.sh
    |-- verify_md5.sh
    `-- verify_run_file.sh
```

## File Roles

| File | Role |
| --- | --- |
| `install.sh` | Default customer entry point. Performs environment checks, then calls `sdk_manager.sh install`. |
| `sdk_manager.sh` | Main SDK package manager. Handles install, update, uninstall, list, verify, and version commands. |
| `sdk.json` | SDK package index. Defines available versions, supported OS/architecture combinations, download URLs, MD5 values, and release note links. |
| `README.md` | Customer usage guide. |
| `VERSION` | Version of this installer repository. |
| `LICENSE` | Repository license. |
| `scripts/` | Internal helper scripts used by `install.sh` and `sdk_manager.sh`. |

## Commands

### Install latest SDK

```bash
sudo bash install.sh
```

Equivalent command:

```bash
sudo bash sdk_manager.sh install
```

### Install a specific SDK version

```bash
sudo bash sdk_manager.sh install --version 1.6.7.2
```

### Install without driver build/load

```bash
sudo bash sdk_manager.sh install --skip-drv
```

### Update SDK

```bash
sudo bash sdk_manager.sh update
```

If update fails, `sdk_manager.sh` attempts to roll back with the cached package
stored at:

```text
/var/cache/azurengine/sdk_release.run
```

### Uninstall SDK

```bash
sudo bash sdk_manager.sh uninstall
```

### List downloadable SDK packages

```bash
bash sdk_manager.sh list
```

### Verify package download and MD5

```bash
bash sdk_manager.sh verify --version 1.6.7.2
```

### Show installed SDK version

```bash
bash sdk_manager.sh version
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

The downloader and package manager scripts require:

| Component | Requirement |
| --- | --- |
| Shell | Bash |
| Python | Python 3, recommended Python 3.11 |
| Downloader | `wget` or `curl` |
| Checksum tool | `md5sum` |
| Privilege | Root permission for install, update, and uninstall |

`scripts/json_query.py` uses the Python standard `json` module to parse
`sdk.json`. Users do not need to call it directly.

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

Systems that do not meet these requirements may encounter installation or
runtime issues.

### Kylin

Supported CPU platforms:

- Hygon
- Phytium

Validated kernel/compiler baseline:

```text
Linux version 5.4.18-152-generic
GCC 9.4.0 (Ubuntu 9.4.0-1ubuntu1~20.04.1)
```

Kylin uses the Debian SDK package mapping in `sdk.json`.

### openEuler

Supported platform:

- x86_64 host

Validated kernel/compiler baseline:

```text
Linux version 6.6.0-127.0.0.125.oe2403sp1.x86_64
GCC 12.3.1 (openEuler 12.3.1-65.oe2403sp1)
GNU Binutils 2.41
```

openEuler uses the openEuler SDK package mapping in `sdk.json`.

## SDK Package Index

To add or update SDK versions, edit `sdk.json` only. Do not hard-code package
URLs in shell scripts.

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
            "url": "https://raw.githubusercontent.com/xdltek/xdl-sdk-artifacts/main/1.6.7.2/azurengine_sw_1.6.7.2_x86_64_debian.run",
            "md5": "741021ce9d34b1f6b8717c2900fa9fbb"
          }
        }
      }
    }
  }
}
```

## Release Notes

Release package files and package-level release notes are hosted in:

```text
https://github.com/xdltek/xdl-sdk-artifacts
```

GitHub release pages can be used for customer-facing release summaries:

```text
https://github.com/xdltek/xdl-sdk/releases
```

## FAQ

### Where are SDK packages stored?

SDK `.run` packages are stored in `xdl-sdk-artifacts`, not in this repository.

### Why use `sdk.json`?

It decouples package metadata from script logic. Future SDK releases should only
require a `sdk.json` update.

### What if MD5 verification fails?

Delete the downloaded file under `downloads/<version>/` and rerun the command.

### What if the OS is detected incorrectly?

Use `--os` and `--arch` overrides:

```bash
sudo bash sdk_manager.sh install --os ubuntu --arch x86_64
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

Install prerequisites once before installing the SDK:

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

If a previous installation attempt left `rpp-dkms` in a half-installed state,
repair the package database before continuing:

```bash
sudo apt --fix-broken install -y
sudo dpkg --configure -a
```

#### openEuler

Install prerequisites once before installing the SDK:

```bash
sudo dnf install -y cmake
sudo dnf install -y dkms
```

Confirm:

```bash
dkms --version
cmake --version
```

## License

This repository is licensed under the Apache License 2.0. See [LICENSE](LICENSE).
