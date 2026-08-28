<p align="center">
  <img src="images/logo_color_horizontal.png" width="340" alt="XDL">
</p>

<h1 align="center">XDL SDK</h1>

<p align="center">
  One installation entry point for the XDL acceleration platform<br>
  <strong>Readiness check · Architecture selection · Secure download · Integrity verification · Guided installation</strong>
</p>

<p align="center">
  <a href="#install-in-three-steps">Quick start</a> ·
  <a href="#support-scope">Support scope</a> ·
  <a href="#what-is-checked-before-installation">Preflight</a> ·
  <a href="release_note_en.md">Release notes</a> ·
  <a href="README.md">中文</a>
</p>

---

## Overview

XDL SDK Installer is the official command-line delivery entry point for the XDL SDK.
This repository does not store large SDK packages. It selects the published package for the
customer host, checks system readiness and dependencies, and verifies the downloaded file's
size and SHA-256 before starting the SDK installer.

| Customer benefit | Description |
| --- | --- |
| Visible readiness | A clear status table covers the OS, kernel, libraries, build tools, driver prerequisites, and network |
| Fail-safe workflow | Installation stops on a broken package database, missing dependency, architecture mismatch, insufficient storage, or unreachable artifact |
| Platform-aware delivery | Detects x86_64/aarch64 automatically and supports explicit package selection |
| Delivery integrity | Uses HTTPS and validates the published file size and SHA-256 |
| Operations-friendly | Supports check-only, download-only, unattended, and custom-directory modes |

> **Current version:** `1.6.7.2`　|　[View changes and known limitations](release_note_en.md)

## Support Scope

| Item | Scope |
| --- | --- |
| Operating-system family | Ubuntu and Debian using APT/dpkg |
| CPU architectures | x86_64 and aarch64 |
| SDK format | Debian `.run` installer |
| Driver integration | DKMS; driver installation is required by the current release |
| Existing field record | Ubuntu 20.04.6 LTS on x86_64; `ae-smi` detected an RPP_R9 device after reboot |

> Run `--check-only` before deployment on every distribution release, kernel, and ARM host.
> A successful script check does not certify a particular accelerator model or workload.

## Install in Three Steps

### 1. Get the installer

```bash
git clone https://github.com/xdltek/xdl-sdk.git
cd xdl-sdk
```

### 2. Run a read-only readiness check (recommended)

```bash
bash install.sh --check-only
```

This command prints the complete readiness report without installing packages, downloading
the SDK, or modifying the host.

### 3. Download and install

```bash
bash install.sh
```

The installer prints the preflight results and installation plan first. If dependencies are
missing, it asks before using APT. It requests final confirmation only after every requirement
has passed.

For unattended installation:

```bash
bash install.sh --yes
```

### Offline or limited-network installation

Obtain the SDK package matching the host architecture through removable storage, an internal
file server, or XDL Technical Support. The repository already includes an empty `downloads/`
directory. Place the package there, then run the same single command:

```text
xdl-sdk/
├── install.sh
└── downloads/
    └── xdl_sdk_1.6.7.2_x86_64_debian.run
```

```bash
bash install.sh
```

For an aarch64 host, use `xdl_sdk_1.6.7.2_aarch64_debian.run`. The installer checks the local
file size and SHA-256 first. A verified local package requires neither `curl` nor proxy or
GitHub access. Online download is used only when the local package is absent or invalid.

If the package is already in another directory, point the installer to that directory without
copying it into the repository:

```bash
bash install.sh --download-dir /data/xdl-sdk
```

### Existing SDK version handling

Before downloading a new package, the installer reads
`/usr/local/rpp/doc/creation_timestamp.txt` and applies these rules:

This appears as a separate `[PRECHECK] Installed SDK status` section and is not one of the
five installation stages. If the requested version is already installed, the installer
shows a final `[RESULT]` and exits, so stages `[1/5]` through `[5/5]` do not appear. The
five-stage workflow starts only when checking, downloading, or installation must continue.

| Installed state | Installer behavior |
| --- | --- |
| Not installed | Continue with the normal preflight, download, and installation |
| Same as the requested version | Clearly report that no action is required and exit successfully; an optional two-step reinstall path emphasizes the uninstall command, the requirement to wait for completion, and the installer rerun command |
| Older than the requested version | Announce the upgrade; after confirmation, finish uninstalling the old SDK and verify removal before downloading and installing the new version |
| Newer than the requested version | Block downgrade; to switch versions, uninstall manually and run the installer again |
| SDK detected but version unknown | Block installation to avoid overwriting an unknown environment; contact XDL Technical Support or uninstall manually |
| SDK packages or `rc` configuration remnants remain after uninstall | List the exact packages; a normal installation cleans and verifies them after confirmation, `--yes` confirms automatically, and `--check-only` prints the exact cleanup command without changing the host |

Unified uninstall command:

```bash
bash uninstall.sh
```

> Uninstall and installation never run concurrently. During an upgrade, the installer waits
> for the uninstaller to finish and verifies that the old SDK record is gone. Any failure
> stops the workflow before the new installation starts. The unified uninstaller also cleans
> and verifies SDK packages and `rc` configuration remnants left by the bundled uninstaller.

## What Is Checked Before Installation

Each item is marked `OK`, `MISSING`, `WARNING`, `SKIPPED`, or `BLOCKED`:

| Category | Checks |
| --- | --- |
| Installed-version precheck | Identify the current SDK before the five-stage workflow and decide whether to finish, upgrade, or block overwrite |
| System compatibility | Distribution, CPU architecture, Linux kernel, APT/dpkg, package database, sudo/root access |
| Base tooling | `coreutils`; `curl` and `ca-certificates` are required only for online download |
| Runtime libraries | `libc6`, `libstdc++6` |
| Build prerequisites | `dctrl-tools`, `build-essential` |
| Driver prerequisites | `dkms`, `linux-headers-$(uname -r)` for the running kernel |
| Delivery readiness | Verify a local package first; check HTTPS proxy and artifact server only when no valid local package exists |

Example:

```text
[2/5] Required packages and libraries
  PACKAGE / LIBRARY                          STATUS     PURPOSE
  curl                                       OK         secure SDK download
  libc6                                      OK         GNU C runtime library
  build-essential                            OK         compiler and build toolchain
  dkms                                       OK         RPP kernel module management
  linux-headers-5.15.0-139-generic           OK         headers for the running kernel

[3/5] SDK package source and storage readiness
  Local SDK package                       OK         /path/to/downloads/xdl_sdk_1.6.7.2_x86_64_debian.run
  Package integrity                       OK         file size and SHA-256 verified
  Network access                          SKIPPED    not required for local installation
  Free disk space                            OK         54.3 GiB available
  Integrity metadata                         OK         SHA-256 is published for this SDK package
```

The SDK installation never starts while a requirement is `MISSING` or `BLOCKED`.
`--check-only` prints copy-ready remediation commands based on the packages actually missing
from the host. For example, when `curl`, `dctrl-tools`, `build-essential`, and `dkms` are
missing during an online installation, it displays:

```bash
sudo apt update
sudo apt install -y curl dctrl-tools build-essential dkms
bash install.sh --check-only
```

For a broken Debian package database, follow the report and run:

```bash
sudo apt --fix-broken install -y
sudo dpkg --configure -a
```

## Common Installation Scenarios

| Scenario | Command |
| --- | --- |
| Detect architecture and install | `bash install.sh` |
| Select x86_64 | `bash install.sh --arch x86_64` |
| Select ARM64 | `bash install.sh --arch aarch64` |
| Check without modifying the host | `bash install.sh --check-only` |
| Download and verify only | `bash install.sh --download-only` |
| Unattended installation | `bash install.sh --yes` |
| Use another download directory | `bash install.sh --download-dir /data/xdl-sdk` |
| Disable terminal colors | `bash install.sh --no-color` |
| Complete uninstall and remnant cleanup | `bash uninstall.sh` |
| Unattended uninstall | `bash uninstall.sh --yes` |

Show complete help:

```bash
bash install.sh --help
```

## Verify the Installation

Show the SDK build record:

```bash
cat /usr/local/rpp/doc/creation_timestamp.txt
```

Check installed package states:

```bash
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

An `ii` state means the package is installed correctly. States such as `iU` or `iF` mean
installation or configuration is incomplete.

After installing the driver, reboot so DKMS can load the module for the running kernel.
Then validate the device (press `q` to exit):

```bash
ae-smi
```

## Uninstall

```bash
bash uninstall.sh
```

This one command runs and waits for the bundled SDK uninstaller, cleans detected SDK packages
and `rc` configuration remnants, and verifies complete removal. For unattended removal:

```bash
bash uninstall.sh --yes
```

## FAQ and Troubleshooting

<details>
<summary><strong>How do I verify Debian packages after installation?</strong></summary>

This SDK uses Debian packages. Use `dpkg`, not `rpm`:

```bash
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

Representative output (components and architecture can differ):

```text
ii  azurengine-ae-smi                         1-1       amd64  Package created with checkinstall 1.6.3
ii  azurengine-graph-loader-py311             1-1       amd64  Package created with checkinstall 1.6.3
ii  azurengine-mppsdk-core-mpu1-mode          1-1       amd64  Package created with checkinstall 1.6.3
ii  azurengine-openrt-core-py311              1-1       amd64  Package created with checkinstall 1.6.3
ii  azurengine-rpp-drv-api-mps-on             1-1       amd64  Package created with checkinstall 1.6.3
ii  azurengine-rpp-mpu-tools                  1-1       amd64  Package created with checkinstall 1.6.3
ii  azurengine-rpp-perf                       1-1       amd64  Package created with checkinstall 1.6.3
ii  azurengine-rpp-system-config              1         all    RPP system config files
ii  azurengine-rpp-tool-chain-main            1-1       amd64  Package created with checkinstall 1.6.3
ii  azurengine-rpp-tool-chain-rppblas         1-1       amd64  Package created with checkinstall 1.6.3
ii  azurengine-rpp-tool-chain-rppfft          1-1       amd64  Package created with checkinstall 1.6.3
ii  rpp-dkms                                  2.0.16.1  all    Azurengine RPP kernel module
```

| State | Meaning | Recommended action |
| --- | --- | --- |
| `ii` | Installed and configured | Ready to use |
| `iU` | Unpacked but not configured | Run `sudo apt --fix-broken install -y` and `sudo dpkg --configure -a` |
| `iF` | Configuration failed | Review the apt/dpkg error and repair dependencies |
| `rc` | Software removed; configuration remains | Use `apt purge` if complete removal is required |

Inspect one package:

```bash
dpkg -s azurengine-rpp-drv-api-mps-on
```

`Status: install ok installed` means the package is healthy.

</details>

<details>
<summary><strong>ae-smi reports “No devices initialized successfully.” What should I do?</strong></summary>

Reboot first so DKMS can load the RPP module for the running kernel. Then run:

```bash
dkms status
lsmod | grep rpp
ae-smi
```

If the host cannot be rebooted, an experienced administrator can inspect and load the
module manually:

```bash
MODULE_DIR="/lib/modules/$(uname -r)/updates/dkms"
ls -lh "$MODULE_DIR"/rpp.ko*

# Run only when rpp.ko.xz exists and rpp.ko does not already exist.
sudo xz -dk "$MODULE_DIR/rpp.ko.xz"
sudo insmod "$MODULE_DIR/rpp.ko"
lsmod | grep rpp
```

For temporary troubleshooting when device nodes exist but access is denied:

```bash
sudo chmod 666 /dev/rpp0_entire_ctrl /dev/ve0_entire_ctrl
```

Mode `666` grants every local user read/write access. Use it only temporarily in a controlled
environment; production systems should use a device group or udev rule with least privilege.
Do not force-load a module after signature, kernel-version, or unresolved-symbol errors.

</details>

<details>
<summary><strong>What if I need to switch the RPP MPS multi-thread/single-thread mode?</strong></summary>

- `azurengine-rpp-drv-api-mps-on`: multi-thread mode; requires `rpp_server`.
- `azurengine-rpp-drv-api-mps-off`: single-thread mode.

The `.deb` packages required for MPS mode switching are **not included in the current
customer delivery**, so this is not a customer self-service operation. Contact XDL Technical
Support and provide the SDK version, CPU architecture, current `rpp-drv-api` package state,
and intended use case. Support will confirm compatibility, provide the matching package,
and guide the change.

```bash
dpkg -l | grep -Ei "rpp-drv-api"
```

Until XDL Technical Support confirms the procedure, do not remove the current package,
install a `.deb` from an unverified source, or install mps-on and mps-off together.

</details>

<details>
<summary><strong>What if rpp-dkms or an rc state remains after uninstall?</strong></summary>

The installer recognizes remaining SDK packages whose names begin with `azurengine-`, `xdl-`,
or `rpp-` and prints the exact names. A normal installation can clean them after one
confirmation; `--yes` confirms automatically. The read-only check never changes the host:

```bash
bash install.sh --check-only
```

For manual investigation, inspect package states and RPP processes:

```bash
dpkg -l | grep -Ei "rpp|azurengine|xdl"
pgrep -af 'rpp_server|rpp'
```

After stopping related workloads, purge only the packages reported by the installer. For example:

```bash
sudo apt purge -y \
  azurengine-rpp-system-config \
  rpp-dkms \
  azurengine-rpp-drv-api-mps-off
sudo dpkg --configure -a
```

An `rc` state means only configuration files remain; `ii` means the package is still installed.
The installer waits for APT and verifies cleanup before starting the new SDK installation.

</details>

<details>
<summary><strong>The artifact server is BLOCKED. What should I check?</strong></summary>

Confirm outbound HTTPS access and review corporate firewall, allowlist, and proxy settings:

```bash
export https_proxy=http://proxy.example.com:port
bash install.sh --check-only
```

HTTP `403` means that the server or CDN rejected the request. Check URL permissions, origin
policy, or the network egress; repeated retries usually do not resolve it. Alternatively,
place the package for the selected architecture under `downloads/`; the installer verifies
its size and SHA-256 and then installs offline:

```bash
bash install.sh
```

</details>

<details>
<summary><strong>Headers for the running kernel are missing. What should I do?</strong></summary>

```bash
sudo apt update
sudo apt install linux-headers-$(uname -r)
```

If an exact match is unavailable, review the kernel source and configured repositories. Do
not substitute headers from another kernel version.

</details>

<details>
<summary><strong>RK3588 driver build fails with “/lib/modules/5.10.160/build: No such file or directory.”</strong></summary>

The build directory or headers for the running kernel are missing. Check the exact kernel
release and link first:

```bash
uname -r
ls -ld /lib/modules/$(uname -r)/build
```

Obtain Linux headers from an official Rockchip or board-vendor release that exactly match
the system image, `uname -r` output, and ARM64 architecture. Example for `5.10.160-31`:

```bash
sudo dpkg -i linux-headers-5.10.160_5.10.160-31_arm64.deb
sudo apt --fix-broken install -y
ls -ld /lib/modules/$(uname -r)/build
```

Do not use the example package with another kernel. If `build` is still missing, request
the matching package from the board vendor or XDL Technical Support.

</details>

<details>
<summary><strong>RK3588 driver build fails with “/usr/bin/env: ‘python’: No such file or directory.”</strong></summary>

Some kernel build scripts invoke `python`, while the host might provide only `python3`.
Install the explicit build dependencies and the distribution-managed Python 3 compatibility
command:

```bash
sudo apt update
sudo apt install -y \
  python3 python-is-python3 \
  git cmake gcc g++ \
  flex bison libboost-all-dev libsqlite3-dev net-tools

python --version
```

Do not perform a full `apt upgrade` only for this error, because that can change the validated
kernel/driver environment. If the board distribution does not provide `python-is-python3`,
contact the board vendor or XDL Technical Support for the compatible solution.

</details>

<details>
<summary><strong>RK3588 driver build fails with “/bin/bash: scripts/basic/fixdep: No such file or directory.”</strong></summary>

Generate the kernel build helper scripts in the running kernel's build directory:

```bash
KERNEL_BUILD="/lib/modules/$(uname -r)/build"
test -d "$KERNEL_BUILD" || echo "Kernel build directory is missing"
cd "$KERNEL_BUILD"
sudo make scripts
test -x scripts/basic/fixdep && echo "fixdep is ready"
```

Even if a later part of `make scripts` reports an error, continue only when the final check
prints `fixdep is ready`. Otherwise the headers/kernel source are incomplete or mismatched,
or another build dependency is missing; contact the board vendor or XDL Technical Support.

</details>

## Security and Data Handling

- SDK packages are downloaded from the configured HTTPS release endpoints.
- File size and SHA-256 are validated to confirm that the download matches the published artifact; this is not a digital signature.
- The repository includes the `downloads/` directory by default. Its `.gitignore` prevents
  downloaded `.run` packages, temporary files, and other local content from being committed
  accidentally. Packages in a customer-selected directory are also outside repository delivery.
- The installer does not collect or upload host information.

## Support

Prepare this diagnostic information before requesting assistance:

```bash
cat /etc/os-release
uname -a
dpkg --audit
dkms status
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

Open an issue in this repository or contact your XDL technical representative. Never
post credentials, tokens, internal addresses, or other sensitive information in a public issue.

---

© XDL. See [LICENSE](LICENSE) for repository licensing information.
