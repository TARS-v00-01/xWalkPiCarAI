<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkUserButton
Simulation

**2. xWalk hardware &middot; Module 66**

<!-- xwalk-page-header:end -->

# xWalkUserButton Simulation

The executable exercises a short active-low press through an in-memory GPIO backend. It does not open
`/dev/gpiochip*` or claim a physical line.

## 1. Overview

`xWalkUserButtonSimulation` is a standalone, device-free host executable. It links the public `xWalkUserButton`
library and `xWalkTrace`, replaces hardware access with an in-memory GPIO backend, and returns 0 only when every
expected observation holds. It never opens `/dev/gpiochip*` or a physical line.

Scenario:

1. Creates the `USER` `XWalkGpio` line as an input with pull-up over `XWalkUserButtonHostStub`.
2. Registers a click callback, starts the monitor, and simulates a press and release with 100 ms and 150 ms
   waits.
3. Expects the press to be observed, the released state afterwards, and exactly one click.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                     Standalone project and `xWalkUserButtonSimulation` target
├── config/
│   └── xHal_Rpi5CarUserButtonTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarUserButtonHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarUserButtonSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarUserButtonSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarUserButtonSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                       Help, argument, and trace handling
    ├── xHal_Rpi5CarUserButtonHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarUserButtonSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarUserButtonSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.228` at start, `RPI.227` when the scenario completes, and `RPI.229` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/simulation -B xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/simulation/build-host --target xWalkUserButtonSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/simulation/build-host/xWalkUserButtonSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_GPIO_BUILD_HOST_TESTS`, `XWALK_GPIO_BUILD_HARDWARE_TESTS`, `XWALK_USER_BUTTON_BUILD_HOST_TESTS`,
`XWALK_USER_BUTTON_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkUserButtonTrace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarUserButtonTraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkUserButtonSimulation.log` below the build directory.
Without the build-time definitions, `xHal_Rpi5CarUserButtonSimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkUserButtonTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkUserButton](../xWalkUserButton.md) host tests.

## 8. Dependencies

- `xWalkUserButton` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/gpiochip*` or a physical line; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkUserButton](../xWalkUserButton.md)
- [xWalkHal Device Layer](../../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../../test/xWalkHal%20Device%20Tests.md)
- [xWalkGpio](../../../interface/xWalkGpio/xWalkGpio.md)

---

[Previous page](../xWalkUserButton.md) · [Chapter index](../../../../../index.md) · [Next page](../../../interface/xWalkHal%20Interface%20Layer.md)
