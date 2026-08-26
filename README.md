<p align="center">
  <img src="images/logo_color_horizontal.png" width="340" alt="XDL">
</p>

<h1 align="center">XDL SDK</h1>

<p align="center">
  面向 XDL 加速平台的一站式 SDK 安装入口<br>
  <strong>环境预检 · 架构适配 · 安全下载 · 完整性校验 · 安装指引</strong>
</p>

<p align="center">
  <a href="#三步完成安装">快速安装</a> ·
  <a href="#支持范围">支持范围</a> ·
  <a href="#安装前会检查什么">安装预检</a> ·
  <a href="release_note.md">版本说明</a> ·
  <a href="README_EN.md">English</a>
</p>

---

## 产品简介

XDL SDK Installer 是 XDL SDK 的官方命令行交付入口。仓库不保存大型 SDK
安装包，而是根据客户主机架构选择正式发布包，在安装前完成系统与依赖检查，下载后
执行文件大小和 SHA-256 完整性校验，全部通过后才启动 SDK 安装。

| 客户价值 | 说明 |
| --- | --- |
| 安装前可见 | 用清晰的状态表展示操作系统、内核、依赖库、构建工具、驱动依赖和网络状态 |
| 风险前置 | 包管理器损坏、依赖缺失、架构不匹配、磁盘不足或下载源不可用时立即停止 |
| 平台适配 | 自动识别 x86_64 / aarch64，也允许显式选择下载架构 |
| 交付可信 | 下载使用 HTTPS，并按发布元数据校验文件大小和 SHA-256 |
| 运维友好 | 支持只检查、只下载、无人值守安装和自定义下载目录 |

> **当前版本：** `1.6.7.2`　|　[查看版本差异与已知限制](release_note.md)

## 支持范围

| 项目 | 支持范围 |
| --- | --- |
| 操作系统家族 | Ubuntu、Debian（APT / dpkg） |
| CPU 架构 | x86_64、aarch64 |
| SDK 安装包 | Debian `.run` 安装包 |
| 驱动方式 | DKMS；当前版本必须安装驱动 |
| 已有现场记录 | Ubuntu 20.04.6 LTS / x86_64；重启后 `ae-smi` 已识别 RPP_R9 设备 |

> 不同发行版版本、内核和 ARM 主机仍应在正式部署前执行 `--check-only`，并按贵司
> 变更流程完成验证。脚本通过不代表特定硬件型号或业务负载已经认证。

## 三步完成安装

### 1. 获取安装工具

```bash
git clone https://github.com/xdltek/xdl-sdk.git
cd xdl-sdk
```

### 2. 只做环境检查（推荐）

```bash
bash install.sh --check-only
```

该命令只输出完整的安装就绪报告，不安装依赖、不下载 SDK、也不修改系统。

### 3. 下载并安装

```bash
bash install.sh
```

脚本会先展示预检结果和安装计划；缺少依赖时会询问是否通过 APT 安装。所有条件
满足后，需要客户再次确认才会下载和安装 SDK。

无人值守安装：

```bash
bash install.sh --yes
```

## 安装前会检查什么

安装器将检查以下内容，并在终端逐项标记 `OK`、`MISSING`、`WARNING`、`SKIPPED`
或 `BLOCKED`：

| 分类 | 检查内容 |
| --- | --- |
| 系统兼容性 | 发行版、CPU 架构、Linux 内核、APT/dpkg、包数据库健康状态、sudo/root 权限 |
| 基础工具 | `curl`、`ca-certificates`、`coreutils` |
| 运行依赖库 | `libc6`、`libstdc++6` |
| 构建依赖 | `dctrl-tools`、`build-essential` |
| 驱动依赖 | `dkms`、当前运行内核对应的 `linux-headers-$(uname -r)` |
| 交付条件 | 可用磁盘空间、HTTPS 代理、SDK 下载源、包大小和 SHA-256 元数据 |

示例：

```text
[2/5] Required packages and libraries
  PACKAGE / LIBRARY                          STATUS     PURPOSE
  curl                                       OK         secure SDK download
  libc6                                      OK         GNU C runtime library
  build-essential                            OK         compiler and build toolchain
  dkms                                       OK         RPP kernel module management
  linux-headers-5.15.0-139-generic           OK         headers for the running kernel

[3/5] Download and storage readiness
  Free disk space                            OK         54.3 GiB available
  Artifact server                            OK         selected package is reachable
  Integrity metadata                         OK         SHA-256 is published for this SDK package
```

出现 `MISSING` 或 `BLOCKED` 时，SDK 安装不会开始。包数据库损坏时请先执行：

`--check-only` 会在报告末尾根据当前主机的实际缺失项生成可直接复制的修复命令。
例如缺少 `curl`、`dctrl-tools`、`build-essential` 和 `dkms` 时会显示：

```bash
sudo apt update
sudo apt install -y curl dctrl-tools build-essential dkms
bash install.sh --check-only
```

如果是包数据库损坏，则按报告提示执行：

```bash
sudo apt --fix-broken install -y
sudo dpkg --configure -a
```

## 常用安装场景

| 场景 | 命令 |
| --- | --- |
| 自动识别架构并安装 | `bash install.sh` |
| 指定 x86_64 | `bash install.sh --arch x86_64` |
| 指定 ARM64 | `bash install.sh --arch aarch64` |
| 只检查、不修改系统 | `bash install.sh --check-only` |
| 只下载并校验 | `bash install.sh --download-only` |
| 无人值守安装 | `bash install.sh --yes` |
| 指定下载目录 | `bash install.sh --download-dir /data/xdl-sdk` |
| 关闭终端颜色 | `bash install.sh --no-color` |

查看完整帮助：

```bash
bash install.sh --help
```

## 安装后验证

### 1. 查看 SDK 版本记录

```bash
cat /usr/local/rpp/doc/creation_timestamp.txt
```

### 2. 检查软件包状态

```bash
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

状态列为 `ii` 表示软件包已正确安装；`iU`、`iF` 等状态表示安装或配置未完成。

### 3. 验证 RPP 设备

完成驱动安装后，建议重启主机，让 DKMS 自动加载与当前内核匹配的模块。重启后执行：

```bash
ae-smi
```

正常显示设备信息表示驱动与设备已生效；按 `q` 退出。

## 卸载

```bash
sudo bash /usr/local/rpp/doc/uninstall.sh
```

卸载后检查是否有残留包：

```bash
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

## FAQ 与异常处理

<details>
<summary><strong>安装后如何确认 Debian 软件包是否正常？</strong></summary>

本 SDK 使用 Debian 包体系，请使用 `dpkg`，不要使用 `rpm`：

```bash
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

正常输出示例（包名会因安装组件和架构不同而变化）：

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

常见状态：

| 状态 | 含义 | 处理建议 |
| --- | --- | --- |
| `ii` | 已安装并正确配置 | 可以使用 |
| `iU` | 已解包但未配置 | 执行 `sudo apt --fix-broken install -y` 和 `sudo dpkg --configure -a` |
| `iF` | 配置失败 | 查看 apt/dpkg 错误并修复依赖 |
| `rc` | 软件已删除，但配置文件残留 | 如需完全清理，使用 `apt purge` |

查看单个包的详细状态：

```bash
dpkg -s azurengine-rpp-drv-api-mps-on
```

其中 `Status: install ok installed` 表示安装正常。

</details>

<details>
<summary><strong>ae-smi 提示 No devices initialized successfully 怎么处理？</strong></summary>

如果出现：

```text
Warning: No devices initialized successfully. init false
Warning: ae-smi init false.
Warning: No DEV to monitor.
```

优先重启主机，让 DKMS 自动加载与当前内核匹配的 RPP 模块。重启后执行：

```bash
dkms status
lsmod | grep rpp
ae-smi
```

如果现场不能重启，可进行高级手动处理：

```bash
MODULE_DIR="/lib/modules/$(uname -r)/updates/dkms"
ls -lh "$MODULE_DIR"/rpp.ko*

# 仅存在 rpp.ko.xz 时解压；不要覆盖已有 rpp.ko
sudo xz -dk "$MODULE_DIR/rpp.ko.xz"

sudo insmod "$MODULE_DIR/rpp.ko"
lsmod | grep rpp
```

如果设备节点存在但当前用户无权访问，可临时按现场方案执行：

```bash
sudo chmod 666 /dev/rpp0_entire_ctrl /dev/ve0_entire_ctrl
```

`chmod 666` 会授予所有本机用户读写权限，只建议用于受控环境的临时排障。生产环境应
由管理员通过设备组或 udev 规则配置最小权限。若 `insmod` 报模块签名、版本不匹配或
符号错误，不要强制加载，应检查 DKMS 构建日志和当前内核版本。

</details>

<details>
<summary><strong>需要切换 RPP MPS 多线程/单线程配置怎么办？</strong></summary>

- `azurengine-rpp-drv-api-mps-on`：多线程模式，需要配合 `rpp_server`。
- `azurengine-rpp-drv-api-mps-off`：单线程模式。

MPS 配置切换所需的 `.deb` 包**不包含在当前客户交付中**，因此不支持客户自行切换。
如业务需要变更模式，请联系 XDL 技术支持人员，并提供 SDK 版本、CPU 架构、当前
`rpp-drv-api` 包状态和使用场景。技术支持将确认兼容性、提供匹配的软件包和操作指导。

```bash
dpkg -l | grep -Ei "rpp-drv-api"
```

在获得 XDL 技术支持确认前，请勿卸载当前包、安装来源不明的 `.deb` 包或同时安装
mps-on 与 mps-off，以免破坏 SDK 依赖关系。

</details>

<details>
<summary><strong>卸载后仍有 rpp-dkms 或 rc 状态怎么办？</strong></summary>

先执行 SDK 自带卸载脚本：

```bash
sudo bash /usr/local/rpp/doc/uninstall.sh
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

确认没有进程占用 RPP：

```bash
pgrep -af 'rpp_server|rpp'
```

停止相关业务后，再按实际残留包执行清理。例如：

```bash
sudo apt purge -y \
  azurengine-rpp-system-config \
  rpp-dkms \
  azurengine-rpp-drv-api-mps-off
sudo dpkg --configure -a
```

`rc` 只表示软件主体已删除但配置文件仍在；`ii` 表示包仍然安装。执行 `apt purge`
前必须核对包名，避免删除仍被其他 XDL 组件使用的依赖。

</details>

<details>
<summary><strong>下载源显示 BLOCKED 怎么办？</strong></summary>

确认目标主机可以访问 HTTPS，检查企业防火墙、白名单和代理设置。如需代理：

```bash
export https_proxy=http://proxy.example.com:port
bash install.sh --check-only
```

HTTP `403` 表示服务器或 CDN 拒绝请求，需要检查链接权限、来源策略或网络出口；
反复重试通常无法解决。

</details>

<details>
<summary><strong>找不到当前内核头文件怎么办？</strong></summary>

```bash
sudo apt update
sudo apt install linux-headers-$(uname -r)
```

如果软件源中没有完全匹配的版本，应先确认当前内核来源和软件源配置，不要用其他
内核版本的 headers 代替。

</details>

<details>
<summary><strong>RK3588 编译驱动提示 /lib/modules/5.10.160/build: No such file or directory 怎么办？</strong></summary>

该错误表示当前内核的构建目录或 Header 不存在。先确认实际内核版本和链接状态：

```bash
uname -r
ls -ld /lib/modules/$(uname -r)/build
```

从瑞芯微（Rockchip）或板卡厂商的官方发布渠道获取与以下三项**完全匹配**的 Linux
Header：当前系统镜像、`uname -r` 输出和 ARM64 架构。以 `5.10.160-31` 包为例：

```bash
sudo dpkg -i linux-headers-5.10.160_5.10.160-31_arm64.deb
sudo apt --fix-broken install -y
ls -ld /lib/modules/$(uname -r)/build
```

示例文件名不能用于其他内核。若安装后 `build` 仍不存在，说明 Header 包与当前板卡
镜像不匹配或包内容不完整，请向板卡厂商或 XDL 技术支持索取对应版本。

</details>

<details>
<summary><strong>RK3588 编译驱动提示 /usr/bin/env: ‘python’: No such file or directory 怎么办？</strong></summary>

部分内核构建脚本调用命令名 `python`，而系统可能只安装了 `python3`。安装明确的构建
依赖，并由发行版提供 `python` 到 Python 3 的兼容入口：

```bash
sudo apt update
sudo apt install -y \
  python3 python-is-python3 \
  git cmake gcc g++ \
  flex bison libboost-all-dev libsqlite3-dev net-tools

python --version
```

不建议仅为此问题执行整机 `apt upgrade`，避免改变已验证的内核和驱动环境。不要从
非可信来源安装名为 `python` 的包；如果板卡发行版不提供 `python-is-python3`，请联系
板卡厂商或 XDL 技术支持确认兼容方案。

</details>

<details>
<summary><strong>RK3588 编译驱动提示 /bin/bash: scripts/basic/fixdep: No such file or directory 怎么办？</strong></summary>

进入当前内核的构建目录并生成内核构建辅助脚本：

```bash
KERNEL_BUILD="/lib/modules/$(uname -r)/build"
test -d "$KERNEL_BUILD" || echo "Kernel build directory is missing"
cd "$KERNEL_BUILD"
sudo make scripts
test -x scripts/basic/fixdep && echo "fixdep is ready"
```

`make scripts` 后续步骤即使出现错误，也只有在最后一条命令确认 `fixdep is ready` 时，
才能继续驱动编译。如果 `scripts/basic/fixdep` 未生成，通常表示 Header/内核源码包不完整、
版本不匹配或仍缺少构建依赖，不要忽略错误，请联系板卡厂商或 XDL 技术支持。

</details>

## 安全与数据说明

- SDK 包通过配置的 HTTPS 发布地址下载。
- 安装器校验发布文件的字节数和 SHA-256；该校验用于确认下载内容与发布制品一致，不等同于数字签名。
- 下载的 `.run` 文件位于 `downloads/` 或客户指定目录，不会提交到 Git。
- 脚本不采集、不上传主机信息。

## 获取支持

提交问题前，请准备以下信息，以便技术支持快速定位：

```bash
cat /etc/os-release
uname -a
dpkg --audit
dkms status
dpkg -l | grep -Ei "rpp|azurengine|xdl"
```

请通过本仓库的 Issue 或您的 XDL 技术支持联系人提交问题。请勿在公开 Issue
中粘贴账号、令牌、内网地址或其他敏感信息。

---

© XDL. See [LICENSE](LICENSE) for repository licensing information.
