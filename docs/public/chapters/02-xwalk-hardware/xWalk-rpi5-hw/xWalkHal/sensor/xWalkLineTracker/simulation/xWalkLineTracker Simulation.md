<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkLineTracker
Simulation

**2. xWalk hardware &middot; Module 108**

<!-- xwalk-page-header:end -->

# xWalkLineTracker Simulation

The executable composes the I2C, ADC, grayscale, and line-tracker APIs over an in-memory bus without opening
`/dev/i2c-*`.

## 1. Overview

`xWalkLineTrackerSimulation` is a standalone, device-free host executable. It links the public `xWalkLineTracker`
library and `xWalkTrace`, replaces hardware access with an in-memory I2C bus, and returns 0 only when every
expected observation holds. It never opens `/dev/i2c-*`.

Scenario:

1. Creates left, middle, and right `XWalkAdc` objects on channels 0, 1, and 2 at address `0x14`.
2. Reads raw values through `XWalkGrayscaleModule` and a line position through `XWalkLineTracker`.
3. Expects raw values `{200, 1000, 1000}`, position `-0.53`, and six I2C reads.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                      Standalone project and `xWalkLineTrackerSimulation` target
├── config/
│   └── xHal_Rpi5CarLineTrackerTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarLineTrackerHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarLineTrackerSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarLineTrackerSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarLineTrackerSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                        Help, argument, and trace handling
    ├── xHal_Rpi5CarLineTrackerHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarLineTrackerSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarLineTrackerSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.241` at start, `RPI.240` when the scenario completes, and `RPI.242` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/simulation -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/simulation/build-host --target xWalkLineTrackerSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/simulation/build-host/xWalkLineTrackerSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_ADC_BUILD_HOST_TESTS`, `XWALK_ADC_BUILD_HARDWARE_TESTS`, `XWALK_LINE_TRACKER_BUILD_HOST_TESTS`,
`XWALK_LINE_TRACKER_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkLineTrackerTrace.xml` from the trace inventory `generated/xwalk-traces.xml`
with `config/xHal_Rpi5CarLineTrackerTraceConfig.py`. The generator preserves previously stored enable and disable
states. Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkLineTrackerSimulation.log` below the build directory.
Without the build-time definitions, `xHal_Rpi5CarLineTrackerSimulationConfig.h` falls back to `xwalk-traces.xml`
and `log/xWalkLineTrackerTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkLineTracker](../xWalkLineTracker.md) host tests.

## 8. Dependencies

- `xWalkLineTracker` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/i2c-*`; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkLineTracker](../xWalkLineTracker.md)
- [xWalkHal Sensor Layer](../../xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Sensor Tests](../../test/xWalkHal%20Sensor%20Tests.md)
- [xWalkAdc](../../../device/xWalkAdc/xWalkAdc.md)

---

[Previous page](../xWalkLineTracker.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkMotor/xWalkMotor.md)
