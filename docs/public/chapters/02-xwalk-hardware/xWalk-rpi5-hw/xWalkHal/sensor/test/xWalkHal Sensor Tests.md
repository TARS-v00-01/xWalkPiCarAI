<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkHal Sensor Tests

**2. xWalk hardware &middot; Module 104**

<!-- xwalk-page-header:end -->

# xWalkHal Sensor Tests

GoogleTest interaction suite for the xWalkHal sensor group. `xWalkSensorGroupTest` composes the line tracker,
motors, LED, and buzzer over deterministic in-memory callbacks.

## 1. Overview

A small test-only response policy, `applyLineResponse`, composes the existing public contracts without adding
production architecture. The suite checks centred and corrective line responses, lost-line safe stop, LED and
buzzer critical indication, recovery, paired-motor command validation, and the motor watchdog and brake arming.
ADC, PWM, I2C, and GPIO behavior uses deterministic in-memory callbacks. The test never drives physical motors,
LEDs, or buzzers.

| Test | Verified behavior |
|---|---|
| `LineResponseGroupTest.TrackerObservationControlsMotorsLedAndBuzzer` | Line position drives motors, LED, buzzer |
| `XWalkSensorGroup.SafeRecoveryStopsAlarmAndRestoresForwardMotion` | Lost-line stop and recovery |
| `XWalkSensorGroup.InvalidMotorPairCommandPreservesBothPreviousSpeeds` | Paired validation before output |
| `XWalkSensorGroup.MotorWatchdogUsesInjectedClockAndStopsDeterministically` | Injected-clock watchdog expiry |
| `XWalkSensorGroup.PairedBrakeRequiresArmingAndExpiresThroughWatchdog` | Brake arming and watchdog expiry |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor/test`

Source directory

## 3. Directory layout

```text
test/
├── CMakeLists.txt                                  xWalkSensorGroupTest target and CTest registration
├── include/xHal_Rpi5CarSensorGroupTestTypes.h      Parameterized line-response case and fixture
└── src/xHal_Rpi5CarSensorGroupTest.cpp             Response policy and group interaction tests
```

The target also compiles the test-support sources of `xWalkLineTracker`, `xWalkMotor`, `xWalkLed`, and
`xWalkBuzzer`.

## 4. Build

`CMakeLists.txt` has no standalone
project. The workspace root `xWalk-rpi5-hw/CMakeLists.txt` adds it when `XWALK_HAL_BUILD_HOST` is on, which
requires `BUILD_TESTING=ON` and `XWALK_BUILD_RPI=OFF`. The target links `GTest::gtest_main`, `gmock`,
`xWalkTrace`, and the `xWalkBuzzer`, `xWalkLed`, `xWalkLineTracker`, and `xWalkMotor` libraries.

## 5. Testing

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw -B xWalk-rpi5-hw/build-host/group-tests -DBUILD_TESTING=ON -DXWALK_BUILD_RPI=OFF -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/build-host/group-tests --target xWalkSensorGroupTest --parallel
```

```bash
xWalk-rpi5-hw/build-host/group-tests/xWalkHal/sensor/test/xWalkSensorGroupTest
```

```bash
ctest --test-dir xWalk-rpi5-hw/build-host/group-tests -L sensor-group --output-on-failure
```

The CTest name is `xWalkSensorGroupTest` with labels `host`, `sensor-group`, and `group-tests`.

## 6. Dependencies

- GoogleTest and GoogleMock (`gmock/gmock.h`, searched below `/usr/src/googletest/googlemock/include`).
- `xWalkTrace` from `xWalk-rpi5-trace`.

## 7. Safety and constraints

The suite is host-only and opens no I2C or GPIO device. It is safe to run on any development host.

## 8. Related notes

- [xWalkHal Sensor Layer](../xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Device Tests](../../device/test/xWalkHal%20Device%20Tests.md)
- [xWalkBuzzer](../xWalkBuzzer/xWalkBuzzer.md)
- [xWalkLed](../xWalkLed/xWalkLed.md)
- [xWalkLineTracker](../xWalkLineTracker/xWalkLineTracker.md)
- [xWalkMotor](../xWalkMotor/xWalkMotor.md)

---

[Previous page](../xWalkBuzzer/simulation/xWalkBuzzer%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkLed/xWalkLed.md)
