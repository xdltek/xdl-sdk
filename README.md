<a id="english"></a>

<p align="center">
  <img src="images/logo_color_horizontal.png" width="320" alt="XDL logo">
</p>

<h1 align="center">XDL SDK</h1>

Language: [English](#english) | [中文](#chinese)

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
|-- VERSION
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
|   |-- verify_run_file.sh
```

## File Roles

| File | Role |
| --- | --- |
| `install.sh` | Customer entry point. Performs environment checks, then starts SDK installation. |
| `sdk_manager.sh` | SDK package manager for install, update, uninstall, list, verify, and version operations. |
| `sdk.json` | SDK package index. Defines versions, supported OS/architecture combinations, download URLs, MD5 values, and release note links. |
| `scripts/json_query.py` | Internal JSON parser used by `sdk_manager.sh`; users do not need to call it directly. |
| `scripts/` | Internal helper scripts for environment checks, download, verification, logging, and compatibility wrappers. |
| `VERSION` | Version of this installer repository. |
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

Customer-facing release summaries can be published through:

```text
https://github.com/xdltek/xdl-sdk/releases
```

## Revision History

| Version | Date | Author | Description |
| --- | --- | --- | --- |
| 1.6.7.2 | 2026-07-15 | XDL Technical Support Team | Initial public SDK delivery release |

## License

This repository is licensed under the Apache License 2.0. See [LICENSE](LICENSE).

---

<a id="chinese"></a>

# XDL SDK 中文说明

语言：[English](#english) | [中文](#chinese)

## 概述

XDL SDK 是 XDL 面向客户、合作伙伴和解决方案团队发布 SDK 的官方交付入口。
它为客户提供统一、可校验、可按平台自动选择的 SDK 获取和安装体验。

通过本仓库，用户可以完成 SDK 的下载、校验、安装、更新、卸载和版本查询。
工具会根据目标系统和 CPU 架构自动选择对应 SDK 安装包，从 XDL 官方发布源下载，
完成 MD5 校验后执行安装流程。

## 核心能力

- 统一安装入口：`install.sh`
- SDK 生命周期管理：`sdk_manager.sh`
- 通过 `sdk.json` 管理版本、平台、下载地址和 MD5
- 按 OS 和 CPU 架构自动选择 SDK 包
- 安装前执行环境和依赖检查
- 安装前执行 MD5 完整性校验
- 支持 install、update、uninstall、list、verify、version
- SDK 更新失败时支持回滚

## 快速开始

```bash
git clone https://github.com/xdltek/xdl-sdk.git
cd xdl-sdk
sudo bash install.sh
```

默认流程：

1. 检查 root 权限、网络、下载工具、磁盘空间、OS、架构和 SDK 安装依赖。
2. 读取 `sdk.json`。
3. 选择 `latest` SDK 版本。
4. 自动识别主机 OS 和 CPU 架构。
5. 下载匹配的 SDK `.run` 安装包。
6. 校验 MD5。
7. 执行 SDK 安装。
8. 缓存安装包，用于后续回滚。

## 仓库结构

```text
xdl-sdk/
|-- install.sh
|-- sdk_manager.sh
|-- sdk.json
|-- README.md
|-- VERSION
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
|   |-- verify_run_file.sh
```

## 文件作用

| 文件 | 作用 |
| --- | --- |
| `install.sh` | 客户默认入口。先执行环境检查，再启动 SDK 安装。 |
| `sdk_manager.sh` | SDK 包管理器，负责安装、更新、卸载、列表、校验和版本查询。 |
| `sdk.json` | SDK 包索引，维护版本、OS/架构、下载地址、MD5 和 Release 信息。 |
| `scripts/json_query.py` | `sdk_manager.sh` 内部使用的 JSON 解析工具，用户无需直接调用。 |
| `scripts/` | 内部辅助脚本，包括环境检查、下载、校验、日志和兼容入口。 |
| `VERSION` | 本安装器仓库版本。 |
| `LICENSE` | 仓库许可证。 |

## 常用命令

只有会修改主机系统的命令需要 root 权限：`install`、`update` 和 `uninstall`。
只读命令或仅下载校验的命令不需要 `sudo`，例如 `list`、`verify` 和 `version`。

安装最新 SDK：

```bash
sudo bash install.sh
```

使用包管理器安装：

```bash
sudo bash sdk_manager.sh install
```

安装指定版本：

```bash
sudo bash sdk_manager.sh install --version 1.6.7.2
```

跳过驱动构建/加载：

```bash
sudo bash sdk_manager.sh install --skip-drv
```

更新 SDK：

```bash
sudo bash sdk_manager.sh update
```

卸载 SDK：

```bash
sudo bash sdk_manager.sh uninstall
```

列出可下载 SDK：

```bash
bash sdk_manager.sh list
```

校验 SDK 包：

```bash
bash sdk_manager.sh verify --version 1.6.7.2
```

查看已安装 SDK 版本：

```bash
bash sdk_manager.sh version
```

## 支持平台

当前 `sdk.json` 支持：

| OS | 架构 | 包映射 |
| --- | --- | --- |
| Ubuntu | `x86_64`, `aarch64` | Debian SDK 包 |
| Debian | `x86_64`, `aarch64` | Debian SDK 包 |
| Kylin | `x86_64`, `aarch64` | Debian SDK 包 |
| openEuler | `x86_64` | openEuler SDK 包 |

自动识别不满足现场环境时，可手动指定：

```bash
sudo bash sdk_manager.sh install --os ubuntu --arch x86_64
```

## 平台要求

### 安装脚本要求

| 组件 | 要求 |
| --- | --- |
| Shell | Bash |
| Python | Python 3，推荐 Python 3.11 |
| 下载工具 | `wget` 或 `curl` |
| 校验工具 | `md5sum` |
| 权限 | install、update、uninstall 需要 root 权限 |

### Ubuntu

支持平台：

- x86_64 主机
- RK3588
- RK3568

最低要求：

| 组件 | 要求 |
| --- | --- |
| 操作系统 | Ubuntu 20.04 LTS 或兼容 Ubuntu 的发行版 |
| 系统内存 | 推荐 >= 16 GB DDR5 |
| CPU 架构 | x86_64 或 aarch64 |
| 编译器 | GCC 9.4.0 或兼容版本 |
| CMake | 推荐 >= 3.26.5 |
| Python | 推荐 Python 3.11 |
| 构建工具 | `build-essential`, `linux-headers`, `dkms`, `dctrl-tools` |

### Kylin

支持 CPU 平台：

- 海光
- 飞腾

已验证内核/编译器基线：

```text
Linux version 5.4.18-152-generic
GCC 9.4.0 (Ubuntu 9.4.0-1ubuntu1~20.04.1)
```

已验证 aarch64 内核基线：

```text
Linux version 6.6.0-58-generic #57-KYLINOS SMP Thu Dec 18 12:24:49 UTC 2025 aarch64
```

### openEuler

支持平台：

- x86_64 主机

已验证内核/编译器基线：

```text
Linux version 6.6.0-127.0.0.125.oe2403sp1.x86_64
GCC 12.3.1 (openEuler 12.3.1-65.oe2403sp1)
GNU Binutils 2.41
```

## SDK 包索引

SDK 包选择由 `sdk.json` 控制。后续新增版本时，应更新 `sdk.json`，
不要把下载地址写死在 Shell 脚本中。

## 故障处理

### 缺少前置依赖

SDK `.run` 安装包中包含 `rpp-dkms`。驱动安装依赖系统中的 `dkms`、
`cmake` 等软件包。缺少依赖时，`rpp-dkms` 可能停留在 `iU` 半安装状态，
并导致包管理器报告破损依赖。

`install.sh` 和 `sdk_manager.sh install/update` 会在执行 SDK 安装前检查这些依赖。
如果发现缺失，会打印安装命令并退出，不会继续修改 SDK 安装状态。

#### Debian / Ubuntu / Kylin

```bash
sudo apt update
sudo apt install -y cmake
sudo apt install -y dkms dctrl-tools build-essential linux-headers-$(uname -r)
```

确认：

```bash
dpkg -l dkms dctrl-tools | grep ^ii
dkms --version
cmake --version
```

如果此前因缺依赖导致 `rpp-dkms` 半安装：

```bash
sudo apt --fix-broken install -y
sudo dpkg --configure -a
```

#### openEuler

```bash
sudo dnf install -y cmake
sudo dnf install -y dkms
```

确认：

```bash
dkms --version
cmake --version
```

## FAQ

### SDK 安装包放在哪里？

SDK `.run` 包由 XDL 官方发布源统一管理，本仓库只提供安装和管理入口。

### MD5 校验失败怎么办？

删除 `downloads/<version>/` 下已下载的文件，然后重新执行命令。

### OS 自动识别不符合现场环境怎么办？

使用 `--os` 和 `--arch` 手动指定：

```bash
sudo bash sdk_manager.sh install --os ubuntu --arch x86_64
```

## 发布说明

- **版本 1.6.7.2**（2026-07-15）：XDL SDK 对外交付入口初始发布，支持按平台
  自动选择 SDK 包、MD5 校验、安装/更新/卸载流程、依赖检查和更新失败回滚。

## 修订历史

| 版本 | 日期 | 作者 | 说明 |
| --- | --- | --- | --- |
| 1.6.7.2 | 2026-07-15 | XDL 技术支持团队 | 对外 SDK 交付初始版本 |

## License

本仓库使用 Apache License 2.0，详见 [LICENSE](LICENSE)。
