<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkAudio
Simulation

**2. xWalk hardware &middot; Module 69**

<!-- xwalk-page-header:end -->

# xWalkAudio Simulation

The standalone `xWalkAudioSimulation` executable runs the public `XWalkAudioAlsa` API through its injected
operation seam and writes one silent period plus a representative volume change.

## 1. Overview

The build-selected backend is either `stub` or `hardware`:

- `stub` (default) mirrors PCM opens, writes, closes, and mixer volume in memory through
  `XWalkAudioHostStub`. It does not open an ALSA endpoint or modify the host mixer.
- `hardware` constructs `XWalkAudioAlsa` with the default `default`, `default`, and `PCM` names and therefore
  opens a physical audio device and changes mixer state.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/simulation` -
source directory

## 3. Directory layout

```text
simulation/
    CMakeLists.txt                                   Standalone project and backend selection
    config/xHal_Rpi5CarAudioTraceConfig.py           Validates and merges the persistent trace catalogue
    include/
        xHal_Rpi5CarAudioHandler.h                   Representative silent playback operations
        xHal_Rpi5CarAudioHostStub.h                  In-memory ALSA operation mirror
        xHal_Rpi5CarAudioSimulation.h                Build-selected composition entry point
        xHal_Rpi5CarAudioSimulationArguments.h       Trace-option parsing
        xHal_Rpi5CarAudioSimulationConfig.h          Trace configuration and log paths
    src/
        main.cpp                                     Executable entry point
        xHal_Rpi5CarAudioHandler.cpp                 Handler implementation
        xHal_Rpi5CarAudioHostStub.cpp                Host stub implementation
        xHal_Rpi5CarAudioSimulationArguments.cpp     Selector validation and persistence
        xHal_Rpi5CarAudioSimulationStub.cpp          Device-free backend composition
        xHal_Rpi5CarAudioSimulationHardware.cpp      Physical ALSA backend composition
```

## 4. Build

`XWALK_AUDIO_SIMULATION_BACKEND` selects `stub` or `hardware`; any other value fails configuration. The project
requires Linux, forces `XWALK_AUDIO_BUILD_LINUX_BACKEND=ON` for the parent module, and links `xWalkAudioAlsa`
and `xWalkTrace`.

From the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/simulation -B xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/simulation/build-stub -DXWALK_AUDIO_SIMULATION_BACKEND=stub -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/simulation/build-stub --target xWalkAudioSimulation --parallel
```

```bash
xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/simulation/build-stub/xWalkAudioSimulation --trace RPI.enable
```

## 5. Configuration

`--trace` accepts one numeric `RPI.<digits>` identifier, the complete `RPI` tag, or `all`, each with `.enable`
or `.disable`, or a JSON trace-update file path. `--help` or `-h` prints usage. A successful selector persists
in the generated `generated/xWalkAudioTrace.xml` and loads automatically on later runs. Enabled messages appear
in the terminal and in `<build directory>/log/xWalkAudioSimulation.log`.

## 6. Safety and constraints

The `stub` backend is device-free. Build `hardware` only on an approved Raspberry Pi audio setup, because it
claims the configured ALSA device and sets mixer volume.

## 7. Related notes

- [xWalkAudio](../xWalkAudio.md)
- [xWalkHal Interface Layer](../../xWalkHal%20Interface%20Layer.md)

---

[Previous page](../xWalkAudio.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkConfig/xWalkConfig.md)
