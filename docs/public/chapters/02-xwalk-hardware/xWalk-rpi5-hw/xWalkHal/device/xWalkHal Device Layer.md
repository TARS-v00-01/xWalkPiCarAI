<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkHal Device Layer

**2. xWalk hardware &middot; Module 51**

<!-- xwalk-page-header:end -->

# xWalkHal Device Layer

The device group of the xWalk Firmware HAL contains hardware device abstractions built on the interface layer:
PWM, ADC, servo, accelerometer, ultrasonic ranging, camera capture, and the user button.

## 1. Overview

Every device module is an independent CMake project with a static C++17 library, an optional host test, an
optional opt-in hardware test, and a standalone host simulation. Device objects receive their bus or callback
dependencies by reference and store non-owning pointers; the caller creates dependencies first and destroys them
last. The `test` directory adds a GoogleTest group interaction suite across the device modules.

| Module | Library | Depends on | Function |
|---|---|---|---|
| `xWalkPwm` | `xWalkPwm` | `xWalkI2c` | Robot HAT PWM channels and shared timers |
| `xWalkAdc` | `xWalkAdc` | `xWalkI2c` | Robot HAT analog channels `A0` through `A7` |
| `xWalkServo` | `xWalkServo` | `xWalkPwm` | Calibrated servo angle and pulse control |
| `xWalkAdxl345` | `xWalkAdxl345` | `xWalkI2c` | Three-axis acceleration in standard gravity |
| `xWalkUltrasonic` | `xWalkUltrasonic` | `xWalkGpio` | Trigger and echo distance in centimeters |
| `xWalkCamera` | `xWalkCamera` | Injected callbacks | JPEG still capture and encoded streaming |
| `xWalkUserButton` | `xWalkUserButton` | `xWalkGpio` | Active-low button monitoring and callbacks |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device`

Source directory

## 3. Directory layout

```text
device/
├── test/               Group interaction test xWalkDeviceGroupTest
├── xWalkAdc/           Robot HAT ADC module
├── xWalkAdxl345/       ADXL345 accelerometer module
├── xWalkCamera/        Camera core and Linux backends
├── xWalkPwm/           Robot HAT PWM module
├── xWalkServo/         Servo module
├── xWalkUltrasonic/    Ultrasonic ranging module
└── xWalkUserButton/    User-button monitor module
```

Each module contains `CMakeLists.txt`, `include` (or `core/include` and `hardware/include` for the camera),
`src`, `simulation`, and `test` directories.

## 4. Child modules

- [xWalkHal Device Tests](test/xWalkHal%20Device%20Tests.md) - GoogleTest group interaction suite.
- [xWalkAdc](xWalkAdc/xWalkAdc.md) - Robot HAT analog-to-digital converter.
- [xWalkAdxl345](xWalkAdxl345/xWalkAdxl345.md) - ADXL345 accelerometer.
- [xWalkCamera](xWalkCamera/xWalkCamera.md) - bounded still capture and encoded live-frame streaming.
- [xWalkPwm](xWalkPwm/xWalkPwm.md) - PWM channels and shared timer state.
- [xWalkServo](xWalkServo/xWalkServo.md) - calibrated servo control.
- [xWalkUltrasonic](xWalkUltrasonic/xWalkUltrasonic.md) - two-pin ultrasonic ranging.
- [xWalkUserButton](xWalkUserButton/xWalkUserButton.md) - active-low user-button monitoring.

## 5. Build

The workspace root `xWalk-rpi5-hw/CMakeLists.txt` adds every device module with `add_subdirectory` and adds
`device/test` only when `XWALK_HAL_BUILD_HOST` is on. Each module can also be configured on its own with its
`XWALK_<MODULE>_BUILD_HOST_TESTS` and `XWALK_<MODULE>_BUILD_HARDWARE_TESTS` options; see the module notes.

## 6. Testing

Host tests first: each module note lists its host-test commands, and the group suite runs with:

```bash
ctest --test-dir xWalk-rpi5-hw/build-host/group-tests -L device-group --output-on-failure
```

Hardware tests are opt-in. List them in a hardware-enabled module build with `ctest -N -L hardware` and never
run them without explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 7. Dependencies

- [xWalkHal Interface Layer](../interface/xWalkHal%20Interface%20Layer.md) - `xWalkI2c` and `xWalkGpio`.
- [xWalkLibrary Common](../../xWalkLibrary/common/xWalkLibrary%20Common.md) - types and Robot HAT constants.
- `xWalk-rpi5-trace` - trace macros and the trace catalogue.

## 8. Related notes

- [xWalkHal](../xWalkHal.md)
- [xWalkHal Sensor Layer](../sensor/xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Layer1](../layer1/xWalkHal%20Layer1.md)

---

[Previous page](../xWalkTest/xSequenceTest/xSequenceTest.md) · [Chapter index](../../../index.md) · [Next page](xWalkAdc/xWalkAdc.md)
