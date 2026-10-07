<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkServo
Simulation

**2. xWalk hardware &middot; Module 62**

<!-- xwalk-page-header:end -->

# xWalkServo Simulation

The executable exercises `XWalkServo` through in-memory PWM and I2C composition. It demonstrates timer setup, angle
conversion, and pulse output without opening `/dev/i2c-1` or moving a physical servo.

## 1. Overview

`xWalkServoSimulation` is a standalone, device-free host executable. It links the public `xWalkServo` library and
`xWalkTrace`, replaces hardware access with in-memory PWM and I2C composition, and returns 0 only when every
expected observation holds. It never opens `/dev/i2c-1` or a physical servo.

Scenario:

1. Composes `XWalkI2c`, `XWalkPwm` on channel 0, and `XWalkServo` over `XWalkServoHostStub`.
2. Calls `initialize()`, sets an angle of 0 degrees, and sets a 1000 microsecond pulse.
3. Expects at least six register writes, a final two-byte write to `XHAL_RPI5CAR_PWM_CHANNEL_REG`, and a PWM
   pulse width of 204 counts.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkServo/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                Standalone project and `xWalkServoSimulation` target
├── config/
│   └── xHal_Rpi5CarServoTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarServoHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarServoSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarServoSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarServoSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                  Help, argument, and trace handling
    ├── xHal_Rpi5CarServoHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarServoSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarServoSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.188` at start, `RPI.187` when the scenario completes, and `RPI.189` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkServo/simulation -B xWalk-rpi5-hw/xWalkHal/device/xWalkServo/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkServo/simulation/build-host --target xWalkServoSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/device/xWalkServo/simulation/build-host/xWalkServoSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_PWM_BUILD_HOST_TESTS`, `XWALK_PWM_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkServoTrace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarServoTraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkServoSimulation.log` below the build directory. Without
the build-time definitions, `xHal_Rpi5CarServoSimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkServoTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkServo](../xWalkServo.md) host tests.

## 8. Dependencies

- `xWalkServo` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/i2c-1` or a physical servo; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkServo](../xWalkServo.md)
- [xWalkHal Device Layer](../../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../../test/xWalkHal%20Device%20Tests.md)
- [xWalkPwm](../../xWalkPwm/xWalkPwm.md)

---

[Previous page](../xWalkServo.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkUltrasonic/xWalkUltrasonic.md)
