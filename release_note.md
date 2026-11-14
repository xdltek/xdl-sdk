# XDL SDK 1.6.11 版本说明

## 版本概览

本版本面向 Ubuntu/Debian 的 x86_64 和 aarch64 平台，增强设备内存信息查询和 GraphIR 工作流，并改进客户安装器的环境检查与修复提示。

> **交付前确认：** 版本 `1.6.11` 的两个架构使用不同的安装包文件名。请根据目标主机架构选择下表中的文件，不要重命名或混用安装包。

## 安装包

| 架构 | 文件 | SHA-256 | 验证状态 |
| --- | --- | --- | --- |
| x86_64 | `xdl_sdk_1.6.11.3_x86_64_debian.run` | `6bd451ee91a275d2886bb1cb11788f0d9fd0d5ee79bf10b37b3476e94844d07b` | 已完成安装验证 |
| aarch64 | `xdl_sdk_1.6.11.4_aarch64_debian.run` | `5f8376ef8b439730966f0a405578010ab787ea8f6253fbe2c07dbbff3858d2ab` | 已完成文件完整性验证；目标板安装待验证 |

安装器会自动识别主机架构，并在执行前验证文件大小和 SHA-256。安装方法请参阅 [README_CN.md](README_CN.md)。

## 新功能

- `ae-smi`：默认启用 `rpp_syscfg.ini` 中的 `mem_usage` 节点，以支持查询设备内存资源。
- GraphIR：支持单个 ONNX 模型导出 IR 和回放 IR。
- GraphIR：支持 YOLOv8m fusion ONNX 模型回放 IR。

## 安装器改进

- 仅检查安装脚本直接使用的基础工具；SDK 运行库、构建工具和驱动依赖由 `.run` 安装器处理。
- 基础工具缺失时显示具体软件包、用途和可复制的 APT 修复命令。
- `--check-only` 不再因可自动修复的依赖缺失而失败。
- 正常安装可在客户确认后自动补齐缺失依赖。
- 安装过程增加五阶段彩色进度标识，并保存完整支持日志；成功后重点提示重启和验证步骤。
- 卸载过程增加三阶段彩色进度标识和完整支持日志，并简化客户屏幕输出。
- 架构不匹配、包管理器损坏、磁盘空间不足、安装包完整性错误等安全问题仍会阻止安装。

## 交付范围和限制

- 本版本提供 CV 和 GraphIR 示例。
- 本版本不提供 VE/OpenStream 基础库和示例。
- YOLOv8m fusion ONNX 支持 IR 回放，不支持 IR 导出。
- GraphIR 的独立部署包和内部测试工具不属于本客户 SDK 交付范围。

## Orange Pi 兼容性说明

Orange Pi 上的系统库和驱动安装方式可能与标准 Ubuntu/Debian 主机不同：

- `rpp_assembler` 需要兼容 `libjsoncpp.so.1` 的 jsoncpp 1.7 运行库。不要将 `libjsoncpp.so.25` 软链接为 `libjsoncpp.so.1`，两者 ABI 不兼容。
- `libRppRT.so` 需要 OpenSSL 1.1 的 `libcrypto.so.1.1`。不要将 OpenSSL 3 的 `libcrypto.so.3` 软链接为 `libcrypto.so.1.1`。
- 如果 `ae-smi` 找不到 `librpp_perf.so.1`，请确认 `/usr/local/rpp/lib` 已加入动态库搜索配置，然后执行 `sudo ldconfig`。
- Orange Pi 暂不支持 DKMS 驱动安装，需要使用与板卡镜像和运行内核匹配的驱动源码构建。
- Orange Pi 的 Debian 包部署可能不生成 `/usr/local/rpp/doc/creation_timestamp.txt`，不能仅依赖该文件判断安装状态。

> **Warning:** 兼容库必须来自可信软件源，并与操作系统版本及 aarch64 架构匹配。不要通过创建跨 ABI 的动态库软链接规避依赖问题。如需兼容包或 Orange Pi 驱动安装指导，请联系 XDL 技术支持。

可使用以下命令检查相关动态库依赖：

```bash
ldd -r /usr/local/rpp_sim/bin/rpp_assembler
ldd -r /usr/local/rpp/lib/libRppRT.so
ldconfig -p | grep -E 'libjsoncpp\.so\.1|libcrypto\.so\.1\.1|librpp_perf\.so\.1'
```

## 验证状态

截至 2026-11-14：

- x86_64 安装已成功完成，包括 DKMS 模块构建和 SDK 软件包安装。
- aarch64 安装包已完成文件大小和 SHA-256 校验。
- aarch64 目标板安装、驱动加载以及两种架构的卸载流程仍需验证。
