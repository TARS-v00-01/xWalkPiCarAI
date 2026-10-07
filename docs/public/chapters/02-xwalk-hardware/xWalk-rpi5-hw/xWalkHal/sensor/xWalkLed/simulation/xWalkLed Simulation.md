<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkLed
Simulation

**2. xWalk hardware &middot; Module 106**

<!-- xwalk-page-header:end -->

# xWalkLed Simulation

The executable composes the GPIO, I2C, PWM, single-color LED, and RGB LED APIs over an in-memory backend. It never
opens `/dev/gpiochip*` or `/dev/i2c-*` and cannot change a physical light output.

## 1. Overview

`xWalkLedSimulation` is a standalone, device-free host executable. It links the public `xWalkLed` library and
`xWalkTrace`, replaces hardware access with an in-memory GPIO and I2C backend, and returns 0 only when every
expected observation holds. It never opens `/dev/gpiochip*` or `/dev/i2c-*`.

Scenario:

1. Switches a single-color `XWalkLed` on the `LED` GPIO line on, then toggles it off.
2. Composes `XWalkRgbLed` over PWM channels 0, 1, and 2 at address `0x14` with a common cathode.
3. Sets color `{12, 34, 56}` and expects the stored color and at least one I2C write.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                              Standalone project and `xWalkLedSimulation` target
├── config/
│   └── xHal_Rpi5CarLedTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarLedHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarLedSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarLedSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarLedSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                Help, argument, and trace handling
    ├── xHal_Rpi5CarLedHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarLedSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarLedSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.269` at start, `RPI.268` when the scenario completes, and `RPI.270` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/simulation -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/simulation/build-host --target xWalkLedSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/simulation/build-host/xWalkLedSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_GPIO_BUILD_HOST_TESTS`, `XWALK_GPIO_BUILD_HARDWARE_TESTS`, `XWALK_PWM_BUILD_HOST_TESTS`,
`XWALK_PWM_BUILD_HARDWARE_TESTS`, `XWALK_LED_BUILD_HOST_TESTS`, `XWALK_LED_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkLedTrace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarLedTraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkLedSimulation.log` below the build directory. Without the
build-time definitions, `xHal_Rpi5CarLedSimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkLedTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkLed](../xWalkLed.md) host tests.

## 8. Dependencies

- `xWalkLed` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/gpiochip*` or `/dev/i2c-*`; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkLed](../xWalkLed.md)
- [xWalkHal Sensor Layer](../../xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Sensor Tests](../../test/xWalkHal%20Sensor%20Tests.md)
- [xWalkGpio](../../../interface/xWalkGpio/xWalkGpio.md)
- [xWalkPwm](../../../device/xWalkPwm/xWalkPwm.md)

---

[Previous page](../xWalkLed.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkLineTracker/xWalkLineTracker.md)
