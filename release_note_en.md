# XDL SDK 1.6.11 Release Notes

## Release summary

This release targets x86_64 and aarch64 Ubuntu/Debian systems. It improves device-memory reporting, adds GraphIR workflows, and makes installer environment checks easier for customers to resolve.

> **Delivery note:** Release `1.6.11` uses different installer filenames for each architecture. Select the file from the table below by host architecture; do not rename or mix packages.

## Packages

| Architecture | File | SHA-256 | Validation status |
| --- | --- | --- | --- |
| x86_64 | `xdl_sdk_1.6.11.3_x86_64_debian.run` | `6bd451ee91a275d2886bb1cb11788f0d9fd0d5ee79bf10b37b3476e94844d07b` | Installation validated |
| aarch64 | `xdl_sdk_1.6.11.4_aarch64_debian.run` | `5f8376ef8b439730966f0a405578010ab787ea8f6253fbe2c07dbbff3858d2ab` | File integrity validated; target-board installation pending |

The installer detects the host architecture and verifies file size and SHA-256 before execution. See [README.md](README.md) for installation instructions.

## New features

- `ae-smi`: enables the `mem_usage` node in `rpp_syscfg.ini` by default for device-memory queries.
- GraphIR: supports IR export and replay for a single ONNX model.
- GraphIR: supports IR replay for YOLOv8m fusion ONNX models.

## Installer improvements

- Checks only base tools used directly by the wrapper; the `.run` installer handles SDK runtime, build, and driver dependencies.
- Reports each missing base tool, its purpose, and a copy-ready APT repair command.
- `--check-only` no longer fails for dependencies that can be installed automatically.
- Normal installation can install missing dependencies after customer confirmation.
- Adds five colored installation stages, saves a complete support log, and prominently shows restart and verification steps after success.
- Adds three colored removal stages and a complete support log while simplifying customer-facing output.
- Architecture mismatch, a broken package database, insufficient disk space, and invalid package integrity still block installation.

## Delivery scope and limitations

- This release includes CV and GraphIR samples.
- VE/OpenStream base libraries and samples are not included.
- YOLOv8m fusion ONNX supports IR replay but does not support IR export.
- Standalone GraphIR deployment packages and internal test tools are outside the customer SDK scope.

## Orange Pi compatibility

Orange Pi system libraries and driver installation can differ from standard Ubuntu/Debian hosts:

- `rpp_assembler` requires a jsoncpp 1.7 runtime compatible with `libjsoncpp.so.1`. Do not link `libjsoncpp.so.25` to `libjsoncpp.so.1`; their ABIs are incompatible.
- `libRppRT.so` requires the OpenSSL 1.1 runtime `libcrypto.so.1.1`. Do not link OpenSSL 3 `libcrypto.so.3` to `libcrypto.so.1.1`.
- If `ae-smi` cannot find `librpp_perf.so.1`, ensure `/usr/local/rpp/lib` is in the dynamic-linker configuration and run `sudo ldconfig`.
- DKMS driver installation is not currently supported on Orange Pi. Build the driver from source matched to the board image and running kernel.
- Debian-package deployment on Orange Pi might not create `/usr/local/rpp/doc/creation_timestamp.txt`; do not use that file as the only installation check.

> **Warning:** Obtain compatibility libraries from a trusted source and match the OS release and aarch64 architecture. Never use cross-ABI library symlinks to bypass dependencies. Contact XDL Technical Support for approved compatibility packages and Orange Pi driver instructions.

Use these commands to inspect the relevant dynamic-library dependencies:

```bash
ldd -r /usr/local/rpp_sim/bin/rpp_assembler
ldd -r /usr/local/rpp/lib/libRppRT.so
ldconfig -p | grep -E 'libjsoncpp\.so\.1|libcrypto\.so\.1\.1|librpp_perf\.so\.1'
```

## Validation status

As of 2026-11-14:

- x86_64 installation completed successfully, including the DKMS module build and SDK packages.
- The aarch64 package passed file-size and SHA-256 verification.
- aarch64 target installation and driver loading, plus uninstall flows on both architectures, remain to be validated.
