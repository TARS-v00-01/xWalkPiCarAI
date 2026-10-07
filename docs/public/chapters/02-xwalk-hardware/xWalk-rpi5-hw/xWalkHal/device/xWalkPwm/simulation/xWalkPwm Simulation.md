<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkPwm
Simulation

**2. xWalk hardware &middot; Module 60**

<!-- xwalk-page-header:end -->

# xWalkPwm Simulation

The executable exercises `XWalkPwm` through an in-memory I2C backend. It demonstrates address selection, timer
setup, duty-cycle output, and fail-safe output without opening `/dev/i2c-1` or accessing a Robot HAT.

## 1. Overview

`xWalkPwmSimulation` is a standalone, device-free host executable. It links the public `xWalkPwm` library and
`xWalkTrace`, replaces hardware access with an in-memory I2C device, and returns 0 only when every expected
observation holds. It never opens `/dev/i2c-1` or a Robot HAT.

Scenario:

1. Creates `XWalkI2c` with probe, register-write, read, and non-throwing `tryWriteRegister` callbacks; no
   register-read callback is supplied.
2. Constructs `XWalkPwm` on channel 0 with automatic addressing and a shared `XWalkPwmTimerState`.
3. Sets a period of 4095 counts and a 25 percent pulse width, then calls `trySetPulseWidthPercent(0.0)`.
4. Expects a successful fail-safe write of a two-byte zero payload to `XHAL_RPI5CAR_PWM_CHANNEL_REG` and at
   least five register writes.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                              Standalone project and `xWalkPwmSimulation` target
├── config/
│   └── xHal_Rpi5CarPwmTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarPwmHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarPwmSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarPwmSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarPwmSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                Help, argument, and trace handling
    ├── xHal_Rpi5CarPwmHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarPwmSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarPwmSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.170` at start, `RPI.169` when the scenario completes, and `RPI.171` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/simulation -B xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/simulation/build-host --target xWalkPwmSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/simulation/build-host/xWalkPwmSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_I2C_BUILD_HOST_TESTS`, `XWALK_I2C_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkPwmTrace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarPwmTraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkPwmSimulation.log` below the build directory. Without the
build-time definitions, `xHal_Rpi5CarPwmSimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkPwmTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkPwm](../xWalkPwm.md) host tests.

## 8. Dependencies

- `xWalkPwm` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/i2c-1` or a Robot HAT; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkPwm](../xWalkPwm.md)
- [xWalkHal Device Layer](../../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../../test/xWalkHal%20Device%20Tests.md)
- [xWalkI2c](../../../interface/xWalkI2c/xWalkI2c.md)

---

[Previous page](../xWalkPwm.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkServo/xWalkServo.md)
