<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkCamera
Simulation

**2. xWalk hardware &middot; Module 57**

<!-- xwalk-page-header:end -->

# xWalkCamera Simulation

The executable exercises `XWalkCamera` through an in-memory capture backend. It demonstrates capture forwarding and
bounded settings without opening a camera, starting a process, or creating an image file.

## 1. Overview

`xWalkCameraSimulation` is a standalone, device-free host executable. It links the public `xWalkCamera` library and
`xWalkTrace`, replaces hardware access with an in-memory capture callback, and returns 0 only when every expected
observation holds. It never opens a camera, a capture process, or an image file.

Scenario:

1. Constructs `XWalkCamera` over the `XWalkCameraHostStub` capture callback with a 1280 x 720 pixel
   configuration and a 2000 ms timeout.
2. Requests one capture to `simulation.jpg`.
3. Expects the returned path, one forwarded capture, and the unchanged width, height, and timeout.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                 Standalone project and `xWalkCameraSimulation` target
├── config/
│   └── xHal_Rpi5CarCameraTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarCameraHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarCameraSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarCameraSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarCameraSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                   Help, argument, and trace handling
    ├── xHal_Rpi5CarCameraHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarCameraSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarCameraSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.220` at start, `RPI.219` when the scenario completes, and `RPI.221` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/simulation -B xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/simulation/build-host --target xWalkCameraSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/simulation/build-host/xWalkCameraSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_CAMERA_BUILD_HOST_TESTS`, `XWALK_CAMERA_BUILD_HARDWARE_TESTS`, `XWALK_CAMERA_BUILD_LINUX_BACKEND`.

## 6. Configuration

The build generates `generated/xWalkCameraTrace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarCameraTraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkCameraSimulation.log` below the build directory. Without
the build-time definitions, `xHal_Rpi5CarCameraSimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkCameraTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkCamera](../xWalkCamera.md) host tests.

## 8. Dependencies

- `xWalkCamera` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens a camera, a capture process, or an image file; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkCamera](../xWalkCamera.md)
- [xWalkHal Device Layer](../../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../../test/xWalkHal%20Device%20Tests.md)

---

[Previous page](../xWalkCamera.md) · [Chapter index](../../../../../index.md) · [Next page](../../test/xWalkHal%20Device%20Tests.md)
