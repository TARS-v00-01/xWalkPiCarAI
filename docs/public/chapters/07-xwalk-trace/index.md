[xWalk documentation](../index.md) / Chapter 7

# 7. Trace

## 1. Section overview

Tracing interfaces, diagnostics, and logging constraints.

## 2. Coverage

- 2 module and guide pages, listed below.
- Source locations, interfaces, build and configuration information, testing, and safety constraints.

## 3. Prerequisites

- Read the workspace chapter and avoid recording credentials or personal data in logs.
- Private component access is needed for source builds; no account is needed to read these notes.

**Start here:** [xWalk-rpi5-trace](xWalk-rpi5-trace/xWalk-rpi5-trace.md).

## 4. Modules and guides

- [xWalk-rpi5-trace](xWalk-rpi5-trace/xWalk-rpi5-trace.md): `xWalkTrace` is the C++17 trace service shared by HAL, Controller, Driver, Library, MQTT node, traffic controller, and OS desktop sources. Tagged traces are build-validated, filtered before format arguments are.
- [OS desktop traces](xWalk-rpi5-trace/docs/OS_TRACES.md): The OS desktop owns `OS.001`–`OS.012`, independently of HAL, Node and Traffic IDs. Host/Pi use the shared trace scanner, catalogue, selectors and file sink. Warnings and errors are unfiltered; normal information is.

## 5. Table of contents

- [Section overview](#1-section-overview)
- [Coverage](#2-coverage)
- [Prerequisites](#3-prerequisites)
- [Modules and guides](#4-modules-and-guides)

---

[Previous chapter](../06-xwalk-tool/index.md) · [Next chapter](../08-xwalk-guides/index.md)

[Previous page](../06-xwalk-tool/index.md) · [Chapter index](index.md) · [Next page](xWalk-rpi5-trace/xWalk-rpi5-trace.md)
