<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkBuzzer
Simulation

**2. xWalk hardware &middot; Module 103**

<!-- xwalk-page-header:end -->

# xWalkBuzzer Simulation

The executable composes the GPIO, I2C, PWM, active-buzzer, and passive-buzzer APIs over an in-memory backend. It
never opens `/dev/gpiochip*` or `/dev/i2c-*` and cannot produce physical sound.

## 1. Overview

`xWalkBuzzerSimulation` is a standalone, device-free host executable. It links the public `xWalkBuzzer` library and
`xWalkTrace`, replaces hardware access with an in-memory GPIO and I2C backend, and returns 0 only when every
expected observation holds. It never opens `/dev/gpiochip*` or `/dev/i2c-*`.

Scenario:

1. Drives an active buzzer on GPIO `D4` on and off and checks the mirrored line state.
2. Composes a passive buzzer over `XWalkPwm` channel 0 at address `0x14` and calls `play(440.0, 0.0)`.
3. Expects passive mode, the buzzer off after the zero-duration tone, and at least one I2C write.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                 Standalone project and `xWalkBuzzerSimulation` target
├── config/
│   └── xHal_Rpi5CarBuzzerTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarBuzzerHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarBuzzerSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarBuzzerSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarBuzzerSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                   Help, argument, and trace handling
    ├── xHal_Rpi5CarBuzzerHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarBuzzerSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarBuzzerSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.284` at start, `RPI.283` when the scenario completes, and `RPI.285` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/simulation -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/simulation/build-host --target xWalkBuzzerSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/simulation/build-host/xWalkBuzzerSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_GPIO_BUILD_HOST_TESTS`, `XWALK_GPIO_BUILD_HARDWARE_TESTS`, `XWALK_PWM_BUILD_HOST_TESTS`,
`XWALK_PWM_BUILD_HARDWARE_TESTS`, `XWALK_BUZZER_BUILD_HOST_TESTS`, `XWALK_BUZZER_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkBuzzerTrace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarBuzzerTraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkBuzzerSimulation.log` below the build directory. Without
the build-time definitions, `xHal_Rpi5CarBuzzerSimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkBuzzerTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkBuzzer](../xWalkBuzzer.md) host tests.

## 8. Dependencies

- `xWalkBuzzer` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/gpiochip*` or `/dev/i2c-*`; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkBuzzer](../xWalkBuzzer.md)
- [xWalkHal Sensor Layer](../../xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Sensor Tests](../../test/xWalkHal%20Sensor%20Tests.md)
- [xWalkGpio](../../../interface/xWalkGpio/xWalkGpio.md)
- [xWalkPwm](../../../device/xWalkPwm/xWalkPwm.md)

---

[Previous page](../xWalkBuzzer.md) · [Chapter index](../../../../../index.md) · [Next page](../../test/xWalkHal%20Sensor%20Tests.md)
