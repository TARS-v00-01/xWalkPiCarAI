<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkMotor
Simulation

**2. xWalk hardware &middot; Module 110**

<!-- xwalk-page-header:end -->

# xWalkMotor Simulation

The executable composes the I2C, PWM, GPIO, and Motor APIs over an in-memory backend. It never opens `/dev/i2c-*`
or `/dev/gpiochip*` and cannot move a physical motor.

## 1. Overview

`xWalkMotorSimulation` is a standalone, device-free host executable. It links the public `xWalkMotor` library and
`xWalkTrace`, replaces hardware access with an in-memory I2C and GPIO backend, and returns 0 only when every
expected observation holds. It never opens `/dev/i2c-*`, `/dev/gpiochip*`, or a motor.

Scenario:

1. Composes `XWalkPwm` channel 13 at address `0x14` and direction GPIO `D4` into `XWalkMotor`.
2. Calls `initialize()`, sets speeds of 35 and -20 percent, and stops the motor.
3. Expects the matching direction level for each sign, a final speed of 0, and at least one I2C write.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                Standalone project and `xWalkMotorSimulation` target
├── config/
│   └── xHal_Rpi5CarMotorTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarMotorHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarMotorSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarMotorSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarMotorSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                  Help, argument, and trace handling
    ├── xHal_Rpi5CarMotorHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarMotorSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarMotorSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.254` at start, `RPI.253` when the scenario completes, and `RPI.255` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/simulation -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/simulation/build-host --target xWalkMotorSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/simulation/build-host/xWalkMotorSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_PWM_BUILD_HOST_TESTS`, `XWALK_PWM_BUILD_HARDWARE_TESTS`, `XWALK_GPIO_BUILD_HOST_TESTS`,
`XWALK_GPIO_BUILD_HARDWARE_TESTS`, `XWALK_MOTOR_BUILD_HOST_TESTS`, `XWALK_MOTOR_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkMotorTrace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarMotorTraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkMotorSimulation.log` below the build directory. Without
the build-time definitions, `xHal_Rpi5CarMotorSimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkMotorTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkMotor](../xWalkMotor.md) host tests.

## 8. Dependencies

- `xWalkMotor` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/i2c-*`, `/dev/gpiochip*`, or a motor; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkMotor](../xWalkMotor.md)
- [xWalkHal Sensor Layer](../../xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Sensor Tests](../../test/xWalkHal%20Sensor%20Tests.md)
- [xWalkPwm](../../../device/xWalkPwm/xWalkPwm.md)
- [xWalkGpio](../../../interface/xWalkGpio/xWalkGpio.md)

---

[Previous page](../xWalkMotor.md) · [Chapter index](../../../../../index.md) · [Next page](../../../simulation/xWalkRobotHat/xWalkRobotHat.md)
