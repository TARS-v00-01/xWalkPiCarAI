[xWalk documentation](../index.md) / Chapter 4

# 4. Software

## 1. Section overview

Desktop applications, user interfaces, configuration, and application tests.

## 2. Coverage

- 17 module and guide pages, listed below.
- Source locations, interfaces, build and configuration information, testing, and safety constraints.

## 3. Prerequisites

- Read the workspace and interface chapters; install the dependencies required by the selected application.
- Private component access is needed for source builds; no account is needed to read these notes.

**Start here:** [xWalk-rpi5-os](xWalk-rpi5-os/xWalk-rpi5-os.md).

## 4. Modules and guides

- [xWalk-rpi5-os](xWalk-rpi5-os/xWalk-rpi5-os.md): `xWalk-rpi5-os` is the native C++17 / Qt 5 Widgets desktop for the Raspberry Pi 5 touchscreen. It builds one executable, `xwalk-pi5car`, that renders the xWalk robot command HUD, owns the Controller and Traffic.
- [xWalk-rpi5-os CI](xWalk-rpi5-os/ci/xWalk-rpi5-os%20CI.md): The desktop's continuous-integration entry point builds the standalone and host profiles, runs every module's Google Tests with Qt offscreen, and verifies a staged installation.
- [xWalkCli](xWalk-rpi5-os/xWalkCli/xWalkCli.md): `xWalkCli` is the pure C++ local JSON transport for the existing desktop process owner. It lets terminal clients and the reconnecting HUD reach the GUI or headless owner without starting a second Controller.
- [xWalkConfig](xWalk-rpi5-os/xWalkConfig/xWalkConfig.md): `xWalkConfig` holds the tracked default deployment settings of the desktop: one profile template per build mode, the standalone demo robot configuration, the generated build-mode header template and the editable help.
- [xWalkConfiguration](xWalk-rpi5-os/xWalkConfiguration/xWalkConfiguration.md): `xWalkConfiguration` provides layered configuration loading and atomic, backup-preserving saves for the desktop and robot configuration files edited through the HUD and CLI.
- [xWalkDeploy](xWalk-rpi5-os/xWalkDeploy/xWalkDeploy.md): `xWalkDeploy` holds the desktop-menu integration, installation rules, optional systemd user services, helper scripts and deployment workarounds for the Pi desktop. Installation does not enable automatic hardware startup.
- [GNOME login keyboard on small displays](xWalk-rpi5-os/xWalkDeploy/GNOME_KEYBOARD.md): The Pi's MPI5001 display reports 800 × 480. Its GNOME login keyboard was visibly missing the bottom row containing the symbol switch and spacebar. The xWalk Android-style C++ keyboard runs inside the signed-in app;.
- [xWalkDesktop](xWalk-rpi5-os/xWalkDesktop/xWalkDesktop.md): `xWalkDesktop` renders the scalable robot HUD and live telemetry display: the artwork canvas, function keys, gauges, camera and Traffic preview, event console, Pi 5 illustration, boot-readiness overlay and shutdown.
- [xWalkKeyboard](xWalk-rpi5-os/xWalkKeyboard/xWalkKeyboard.md): `xWalkKeyboard` implements the native C++ Android-style touch keyboard, the shared holographic HUD style for touch dialogs, and touch-sized message prompts through Qt Widgets.
- [xWalkMain](xWalk-rpi5-os/xWalkMain/xWalkMain.md): `xWalkMain` is the application entry point of `xwalk-pi5car`. It composes the desktop, keyboard and CLI modules, parses command-line options, wires keyboard shortcuts and provides the host preview entry point.
- [xWalkNetwork](xWalk-rpi5-os/xWalkNetwork/xWalkNetwork.md): `xWalkNetwork` provides the asynchronous Wi-Fi configuration dialog through NetworkManager and the cached wireless-link check used by the HUD status indicator.
- [xWalkResources](xWalk-rpi5-os/xWalkResources/xWalkResources.md): `xWalkResources` holds the original HUD, boot and shutdown artwork, the Pi 5 mesh with its provenance and license, the boot animation and the Qt resource manifest template. The images remain unchanged and are.
- [xWalkRuntime](xWalk-rpi5-os/xWalkRuntime/xWalkRuntime.md): `xWalkRuntime` owns the Controller and Traffic processes and their shutdown, polls read-only telemetry, evaluates boot readiness and estimates battery charging from the voltage trend.
- [xWalkSettings](xWalk-rpi5-os/xWalkSettings/xWalkSettings.md): `xWalkSettings` is the touch dialog that selects, filters and edits configuration files, with numeric sliders whose limits are shared with CLI configuration edits.
- [xWalkStub](xWalk-rpi5-os/xWalkStub/xWalkStub.md): `xWalkStub` provides the hardware-free C++ service and Wi-Fi simulator used by standalone builds and tests, and the file-only trace adapter that replaces the shared trace backend in the standalone profile.
- [xWalkTest](xWalk-rpi5-os/xWalkTest/xWalkTest.md): `xWalkTest` provides the shared Google Test main, the harmless C++ process and NetworkManager fixture, and the `xwalk_os_add_test` CMake function that gives every desktop module its own test executable and CTest label.
- [xWalk OS CLI guide](xWalk-rpi5-os/CLI_GUIDE.md): The same pure C++ executable supports the standalone, host and Raspberry Pi 5 profiles. `--gui` opens the HUD; `--cli` selects terminal commands. `--fullscreen` opens the GUI fullscreen. Run commands from.

## 5. Table of contents

- [Section overview](#1-section-overview)
- [Coverage](#2-coverage)
- [Prerequisites](#3-prerequisites)
- [Modules and guides](#4-modules-and-guides)

---

[Previous chapter](../03-xwalk-interface/index.md) · [Next chapter](../05-xwalk-node/index.md)

[Previous page](../03-xwalk-interface/index.md) · [Chapter index](index.md) · [Next page](xWalk-rpi5-os/xWalk-rpi5-os.md)
