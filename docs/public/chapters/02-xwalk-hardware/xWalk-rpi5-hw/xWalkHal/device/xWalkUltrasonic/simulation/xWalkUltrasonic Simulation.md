<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkUltrasonic
Simulation

**2. xWalk hardware &middot; Module 64**

<!-- xwalk-page-header:end -->

# xWalkUltrasonic Simulation

The executable exercises `XWalkUltrasonic` through an in-memory GPIO backend. It demonstrates trigger sequencing,
echo timing, and distance conversion without opening `/dev/gpiochip*` or driving physical pins.

## 1. Overview

`xWalkUltrasonicSimulation` is a standalone, device-free host executable. It links the public `xWalkUltrasonic`
library and `xWalkTrace`, replaces hardware access with an in-memory GPIO backend, and returns 0 only when every
expected observation holds. It never opens `/dev/gpiochip*` or physical pins.

Scenario:

1. Creates trigger `D2` and echo `D3` `XWalkGpio` objects over `XWalkUltrasonicHostStub` callbacks.
2. Performs one `read(1U)` distance measurement.
3. Expects a distance between 10 cm and 50 cm, one trigger pulse, and three trigger writes.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                     Standalone project and `xWalkUltrasonicSimulation` target
├── config/
│   └── xHal_Rpi5CarUltrasonicTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarUltrasonicHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarUltrasonicSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarUltrasonicSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarUltrasonicSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                       Help, argument, and trace handling
    ├── xHal_Rpi5CarUltrasonicHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarUltrasonicSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarUltrasonicSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.208` at start, `RPI.207` when the scenario completes, and `RPI.209` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/simulation -B xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/simulation/build-host --target xWalkUltrasonicSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/simulation/build-host/xWalkUltrasonicSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_GPIO_BUILD_HOST_TESTS`, `XWALK_GPIO_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkUltrasonicTrace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarUltrasonicTraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkUltrasonicSimulation.log` below the build directory.
Without the build-time definitions, `xHal_Rpi5CarUltrasonicSimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkUltrasonicTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkUltrasonic](../xWalkUltrasonic.md) host tests.

## 8. Dependencies

- `xWalkUltrasonic` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/gpiochip*` or physical pins; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkUltrasonic](../xWalkUltrasonic.md)
- [xWalkHal Device Layer](../../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../../test/xWalkHal%20Device%20Tests.md)
- [xWalkGpio](../../../interface/xWalkGpio/xWalkGpio.md)

---

[Previous page](../xWalkUltrasonic.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkUserButton/xWalkUserButton.md)
