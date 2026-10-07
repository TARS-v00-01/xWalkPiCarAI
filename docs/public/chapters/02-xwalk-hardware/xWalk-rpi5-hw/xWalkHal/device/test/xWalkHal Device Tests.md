<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkHal Device Tests

**2. xWalk hardware &middot; Module 58**

<!-- xwalk-page-header:end -->

# xWalkHal Device Tests

GoogleTest interaction suite for the xWalkHal device group. `xWalkDeviceGroupTest` composes the public device
APIs over deterministic in-memory callbacks and complements the individual module tests.

## 1. Overview

The suite checks Servo-to-PWM-to-I2C mapping, ADC and accelerometer decoding, GPIO pulse measurement, camera
capture, active-low button behavior, boundary values, and lower-level failure propagation. I2C, GPIO, clocks,
and camera capture use deterministic in-memory callbacks. The test does not access a Raspberry Pi, Robot HAT, or
camera device.

| Test | Verified behavior |
|---|---|
| `BoundaryAngles/ServoAngleGroupTest` | -120, 0, +120 degrees give 102, 307, 511 counts on register `0x20` |
| `XWalkDeviceGroup.ServoPropagatesPwmI2cWriteFailure` | I2C write failures propagate; the servo recovers |
| `XWalkDeviceGroup.AdcAndAccelerometerPreserveBusEncoding` | ADC command and sample, ADXL345 register reads |
| `XWalkDeviceGroup.UltrasonicConvertsOnlyCompleteEchoPulses` | Timeout and incomplete-pulse status results |
| `XWalkDeviceGroup.CameraUsesOnlyInjectedCaptureBoundary` | Capture forwarding, defaults, and failure reporting |
| `XWalkDeviceGroup.UserButtonPreservesActiveLowGpioAndThresholdBoundaries` | Pull-up input and threshold checks |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/test`

Source directory

## 3. Directory layout

```text
test/
├── CMakeLists.txt                                  xWalkDeviceGroupTest target and CTest registration
├── include/
│   ├── xHal_Rpi5CarDeviceGroupTestSupport.h        xwalk::hal::test::device_group failing I2C backend
│   └── xHal_Rpi5CarDeviceGroupTestTypes.h          Parameterized servo-angle case and fixture
└── src/
    ├── xHal_Rpi5CarDeviceGroupTest.cpp             Group interaction tests
    └── xHal_Rpi5CarDeviceGroupTestSupport.cpp      Failing I2C backend callbacks
```

The target also compiles the test-support sources of `xWalkPwm`, `xWalkAdc`, `xWalkAdxl345`,
`xWalkUltrasonic`, `xWalkCamera`, and `xWalkUserButton`, and the camera OpenCV stream backend source.

## 4. Build

`CMakeLists.txt` has no standalone
project. The workspace root `xWalk-rpi5-hw/CMakeLists.txt` adds it when `XWALK_HAL_BUILD_HOST` is on, which
requires `BUILD_TESTING=ON` and `XWALK_BUILD_RPI=OFF`. The target links `GTest::gtest_main`, `gmock`, OpenCV, and
the `xWalkAdc`, `xWalkAdxl345`, `xWalkCamera`, `xWalkPwm`, `xWalkServo`, `xWalkUltrasonic`, and
`xWalkUserButton` libraries.

## 5. Testing

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw -B xWalk-rpi5-hw/build-host/group-tests -DBUILD_TESTING=ON -DXWALK_BUILD_RPI=OFF -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/build-host/group-tests --target xWalkDeviceGroupTest --parallel
```

```bash
xWalk-rpi5-hw/build-host/group-tests/xWalkHal/device/test/xWalkDeviceGroupTest
```

```bash
ctest --test-dir xWalk-rpi5-hw/build-host/group-tests -L device-group --output-on-failure
```

The CTest name is `xWalkDeviceGroupTest` with labels `host`, `device-group`, and `group-tests`.

## 6. Dependencies

- GoogleTest and GoogleMock (`gmock/gmock.h`, searched below `/usr/src/googletest/googlemock/include`).
- OpenCV `core`, `imgcodecs`, and `videoio`.
- `xWalkTrace` from `xWalk-rpi5-trace`.

## 7. Safety and constraints

The suite is host-only and opens no I2C, GPIO, or camera device. It is safe to run on any development host.

## 8. Related notes

- [xWalkHal Device Layer](../xWalkHal%20Device%20Layer.md)
- [xWalkHal Sensor Tests](../../sensor/test/xWalkHal%20Sensor%20Tests.md)
- [xWalkAdc](../xWalkAdc/xWalkAdc.md)
- [xWalkAdxl345](../xWalkAdxl345/xWalkAdxl345.md)
- [xWalkCamera](../xWalkCamera/xWalkCamera.md)
- [xWalkPwm](../xWalkPwm/xWalkPwm.md)
- [xWalkServo](../xWalkServo/xWalkServo.md)
- [xWalkUltrasonic](../xWalkUltrasonic/xWalkUltrasonic.md)
- [xWalkUserButton](../xWalkUserButton/xWalkUserButton.md)

---

[Previous page](../xWalkCamera/simulation/xWalkCamera%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkPwm/xWalkPwm.md)
