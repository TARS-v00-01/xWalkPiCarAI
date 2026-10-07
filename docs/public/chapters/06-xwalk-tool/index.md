[xWalk documentation](../index.md) / Chapter 6

# 6. Tools

## 1. Section overview

Developer tools, build checks, deployment interfaces, and quality verification.

## 2. Coverage

- 10 module and guide pages, listed below.
- Source locations, interfaces, build and configuration information, testing, and safety constraints.

## 3. Prerequisites

- Use an initialized workspace and inspect each tool’s prerequisites before running it.
- Private component access is needed for source builds; no account is needed to read these notes.

**Start here:** [C++ Quality Tool](xWalk-rpi5-tool/cpp-tool/quality/C%2B%2B%20Quality%20Tool.md).

## 4. Modules and guides

- [C++ Quality Tool](xWalk-rpi5-tool/cpp-tool/quality/C%2B%2B%20Quality%20Tool.md): The C++ quality tool stores the intentionally defective sanitizer probes and documents the host quality instrumentation: sanitizers, coverage, Valgrind, Clang Static Analyzer, and ShellCheck. These checks execute.
- [Fuzz Testing Tool](xWalk-rpi5-tool/cpp-tool/fuzz/Fuzz%20Testing%20Tool.md): The fuzz testing tool builds nine Clang/libFuzzer targets that exercise production JSON-C, generated Protobuf, bounded HTTP, camera-source, and OpenCV decode entry points of the xWalk host build.
- [Developer Tool](xWalk-rpi5-tool/py-agent/dev-tool/Developer%20Tool.md): `dev-tool` contains the executable Python utilities used for xWalk development: dependency preparation, interface generation, licence configuration, code-health and condition checks, Zuul validation, runtime.
- [Styler Tool](xWalk-rpi5-tool/py-agent/dev-tool/styler-tool/Styler%20Tool.md): `xWalkStyler` formats and validates project-owned C++ sources and headers with the xWalk mandatory style. It is safe for local use, GitHub Actions, and Gerrit CI, supports paths containing spaces, and never edits.
- [Deployment Tool](xWalk-rpi5-tool/shell-agent/deploy-tool/Deployment%20Tool.md): `deploy-tool` contains the reviewed Raspberry Pi provisioning, cross-build audit, package-installation, service, udev, tmpfiles, and host-test assets for xWalk. Run commands from the integrated repository root.
- [SearXNG Deployment](xWalk-rpi5-tool/shell-agent/deploy-tool/searxng/SearXNG%20Deployment.md): The SearXNG deployment provides an optional, loopback-only SearXNG metasearch container for Jarvis web search on the target. Jarvis continues to answer from local Ollama when SearXNG is absent or web search is disabled.
- [ARM64 cross-build from Linux x86](xWalk-rpi5-tool/shell-agent/deploy-tool/ARM64_CROSS_BUILD.md): The checked-in toolchain prevents CMake from resolving x86 headers or libraries for an AArch64 target. A complete, reviewed ARM64 sysroot is required; the cross compiler alone is not sufficient.
- [Hardware-independent Raspberry Pi 5 readiness](xWalk-rpi5-tool/shell-agent/deploy-tool/HARDWARE_INDEPENDENT_READINESS.md): > [!IMPORTANT] > `/usr/bin/xwalk-picarx-control` and its Doctor command are temporarily unavailable after deletion of the former > Platform composition. Command examples are historical until the replacement Control.
- [Quality Tool](xWalk-rpi5-tool/shell-agent/quality-tool/Quality%20Tool.md): `quality-tool` contains the shared host-safe quality wrappers used locally, by GitHub Actions, and by Gerrit and Zuul: sanitizers, coverage, Valgrind, Clang Static Analyzer, ShellCheck, and dependency inspection.
- [Repository Tool](xWalk-rpi5-tool/shell-agent/repo-tool/Repository%20Tool.md): `repo-tool` contains guarded maintenance commands for the complete xWalk workspace. Its `clean-build.sh` script finds generated CMake and Python output and removes it only after a reviewed preview and explicit.

## 5. Table of contents

- [Section overview](#1-section-overview)
- [Coverage](#2-coverage)
- [Prerequisites](#3-prerequisites)
- [Modules and guides](#4-modules-and-guides)

---

[Previous chapter](../05-xwalk-node/index.md) · [Next chapter](../07-xwalk-trace/index.md)

[Previous page](../05-xwalk-node/index.md) · [Chapter index](index.md) · [Next page](xWalk-rpi5-tool/cpp-tool/quality/C%2B%2B%20Quality%20Tool.md)
