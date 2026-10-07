<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkHal Sensor Layer

**2. xWalk hardware &middot; Module 101**

<!-- xwalk-page-header:end -->

# xWalkHal Sensor Layer

The sensor group of the xWalk Firmware HAL contains sensor and actuator components built on the device and
interface layers: line tracking, motors, LEDs, and buzzers.

## 1. Overview

Every sensor module is an independent CMake project with a static C++17 library, an optional host test, an
optional opt-in hardware test or hardware-dependency build, and a standalone host simulation. Components receive
their ADC, PWM, or GPIO dependencies by reference and store non-owning pointers. The `test` directory adds a
GoogleTest group interaction suite across the sensor modules.

| Module | Library | Depends on | Function |
|---|---|---|---|
| `xWalkLineTracker` | `xWalkLineTracker` | `xWalkAdc` | Grayscale classification, cliff and line detection |
| `xWalkMotor` | `xWalkMotor` | `xWalkPwm`, `xWalkGpio` | Single and paired motors with watchdog |
| `xWalkLed` | `xWalkLed` (alias `xWalkRgbLed`) | `xWalkGpio`, `xWalkPwm` | Single-color and RGB LEDs |
| `xWalkBuzzer` | `xWalkBuzzer` | `xWalkPwm`, `xWalkGpio` | Active and passive buzzers |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor`

Source directory

## 3. Directory layout

```text
sensor/
├── test/                Group interaction test xWalkSensorGroupTest
├── xWalkBuzzer/         Active and passive buzzer module
├── xWalkLed/            Single-color and RGB LED module
├── xWalkLineTracker/    Grayscale and line-tracking module
└── xWalkMotor/          Single and paired motor module
```

Each module contains `CMakeLists.txt`, `include`, `src`, `simulation`, and `test` directories.

## 4. Child modules

- [xWalkHal Sensor Tests](test/xWalkHal%20Sensor%20Tests.md) - GoogleTest group interaction suite.
- [xWalkBuzzer](xWalkBuzzer/xWalkBuzzer.md) - active GPIO and passive PWM buzzers.
- [xWalkLed](xWalkLed/xWalkLed.md) - GPIO LED with blinking and PWM RGB LED.
- [xWalkLineTracker](xWalkLineTracker/xWalkLineTracker.md) - three-channel grayscale line tracking.
- [xWalkMotor](xWalkMotor/xWalkMotor.md) - single and paired motor control.

## 5. Build

The workspace root `xWalk-rpi5-hw/CMakeLists.txt` adds every sensor module with `add_subdirectory` and adds
`sensor/test` only when `XWALK_HAL_BUILD_HOST` is on. Each module can also be configured on its own with its
`XWALK_<MODULE>_BUILD_HOST_TESTS` and `XWALK_<MODULE>_BUILD_HARDWARE_TESTS` options; see the module notes.

## 6. Testing

Host tests first: each module note lists its host-test commands, and the group suite runs with:

```bash
ctest --test-dir xWalk-rpi5-hw/build-host/group-tests -L sensor-group --output-on-failure
```

Hardware tests are opt-in. List them in a hardware-enabled module build with `ctest -N -L hardware` and never
run them without explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup. Motor hardware tests
additionally require raised wheels and a reachable power cut-off.

## 7. Dependencies

- [xWalkHal Device Layer](../device/xWalkHal%20Device%20Layer.md) - `xWalkAdc` and `xWalkPwm`.
- [xWalkHal Interface Layer](../interface/xWalkHal%20Interface%20Layer.md) - `xWalkI2c` and `xWalkGpio`.
- [xWalkLibrary Common](../../xWalkLibrary/common/xWalkLibrary%20Common.md) - types and Robot HAT constants.
- `xWalk-rpi5-trace` - trace macros and the trace catalogue.

## 8. Related notes

- [xWalkHal](../xWalkHal.md)
- [xWalkHal Layer1](../layer1/xWalkHal%20Layer1.md)

---

[Previous page](../layer1/xWalkVoiceAssistant/simulation/xWalkVoiceAssistant%20Simulation.md) · [Chapter index](../../../index.md) · [Next page](xWalkBuzzer/xWalkBuzzer.md)
