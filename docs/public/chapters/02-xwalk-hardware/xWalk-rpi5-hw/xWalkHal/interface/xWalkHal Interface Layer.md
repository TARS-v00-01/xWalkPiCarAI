<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkHal Interface Layer

**2. xWalk hardware &middot; Module 67**

<!-- xwalk-page-header:end -->

# xWalkHal Interface Layer

The interface layer is the lowest group of the xWalk HAL. It contains the platform bus and digital interfaces
(I2C, SPI, GPIO), shared audio, configuration, and utility services, the language-model and web-search
clients, and a group interaction test that exercises these modules together.

## 1. Overview

Each interface module is an independent CMake project with its own options, host tests, and standalone
simulation where applicable. Every module exposes a callback- or operations-table boundary so that host
tests and simulations inject deterministic fakes, while production code injects Linux or provider backends.
Higher HAL layers (`device`, `sensor`, and `layer1`) and `xWalkDriver` components consume these modules.

`xWalk-rpi5-hw/xWalkLibrary/common` remains repository-wide build infrastructure outside this group because
HAL, Agent, Controller, IW, and Trace components all consume it.

The directory has no `CMakeLists.txt` of its own. The workspace build in
`xWalk-rpi5-hw/CMakeLists.txt` adds each module directly and
adds `test` only for the host profile.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface` - source directory

## 3. Directory layout

```text
interface/
    test/                  Group interaction test across the interface modules
    xWalkAudio/            ALSA PCM and mixer boundary
    xWalkConfig/           INI-style configuration file and store
    xWalkGpio/             Robot HAT GPIO lines with Linux character-device backend
    xWalkI2c/              I2C bus access with Linux backend
    xWalkLanguageModel/    Provider-neutral language-model conversation client
    xWalkSpi/              SPI transfers with Linux spidev backend
    xWalkUtils/            Shared utilities with optional Linux backend
    xWalkWebSearch/        Bounded loopback SearXNG search client
```

## 4. Child modules

- [xWalkHal Interface Tests](test/xWalkHal%20Interface%20Tests.md) - group interaction test
  `xWalkInterfaceGroupTest`.
- [xWalkAudio](xWalkAudio/xWalkAudio.md) - audio stream types and the ALSA backend.
- [xWalkConfig](xWalkConfig/xWalkConfig.md) - configuration file access and configuration store.
- [xWalkGpio](xWalkGpio/xWalkGpio.md) - Robot HAT GPIO abstraction and Linux backend.
- [xWalkI2c](xWalkI2c/xWalkI2c.md) - I2C abstraction and Linux backend.
- [xWalkLanguageModel](xWalkLanguageModel/xWalkLanguageModel.md) - language-model client and providers.
- [xWalkSpi](xWalkSpi/xWalkSpi.md) - SPI abstraction and Linux backend.
- [xWalkUtils](xWalkUtils/xWalkUtils.md) - shared utility functions and Linux helpers.
- [xWalkWebSearch](xWalkWebSearch/xWalkWebSearch.md) - bounded local web-search client.

## 5. Build

The workspace build enables every module host test when `BUILD_TESTING` is `ON` and `XWALK_BUILD_RPI` is
`OFF`. Host and Raspberry Pi verification require separate build directories. From the repository root:

```bash
cmake -S xWalk-rpi5-hw -B build-host/group-tests -DBUILD_TESTING=ON -DXWALK_BUILD_RPI=OFF -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-host/group-tests --parallel
```

Each module can also be configured standalone; see the module notes for options and commands.

## 6. Testing

Host tests first. The group interaction test carries the labels `host`, `interface-group`, and
`group-tests`:

```bash
ctest --test-dir build-host/group-tests -L interface-group --output-on-failure
```

Module hardware tests exist for GPIO, I2C, SPI, audio, utilities, and the language model. They are opt-in and
are built only by a Raspberry Pi configuration; list them without running them:

```bash
ctest --test-dir build-rpi -N -L hardware
```

## 7. Safety and constraints

- All interface host tests and the group test use deterministic in-memory callbacks and do not access
  physical devices or services.
- Run no hardware test without explicit approval and a confirmed, safe Raspberry Pi and Robot HAT setup.

## 8. Related notes

- [xWalkHal](../xWalkHal.md)
- [xWalkLibrary Common](../../xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalk-rpi5-trace](../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../device/xWalkUserButton/simulation/xWalkUserButton%20Simulation.md) · [Chapter index](../../../index.md) · [Next page](xWalkAudio/xWalkAudio.md)
