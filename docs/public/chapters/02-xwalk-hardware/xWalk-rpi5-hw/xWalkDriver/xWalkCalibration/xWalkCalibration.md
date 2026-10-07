<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkCalibration

**2. xWalk hardware &middot; Module 08**

<!-- xwalk-page-header:end -->

# xWalkCalibration

`xWalkCalibration` is the Calibration functional group of the xWalk Agent layer. It groups the grayscale,
servo and motor, and servo-zeroing coordinators behind the `xWalk::AgentCalibration` interface target.

## 1. Overview

Every child module remains an independent CMake target with its own public headers. Calibration remains
explicit and bounded: pending values are persisted only by an explicit `save()` call, every wait polls
cancellation, and physical sensor, motor, and servo verification still requires the documented hardware
safety approval.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkCalibration`
(source directory)

## 3. Directory layout

```text
xWalkCalibration/
    CMakeLists.txt                  Group options, xWalk::AgentCalibration target, and group test registration
    test/
        src/                        xWalkDriverCalibrationGroupTest host suite
        hardware/src/               xWalkDriverCalibrationGroupHardwareTest hardware-profile suite
    xWalkGrayscaleCalibration/      Line and cliff reference calibration
    xWalkServoMotorCalibration/     Servo offset and motor direction calibration
    xWalkServoZeroing/              Twelve-channel Robot HAT servo zeroing
```

## 4. Child modules

- [xWalkGrayscaleCalibration](xWalkGrayscaleCalibration/xWalkGrayscaleCalibration.md): line and cliff references.
- [xWalkServoMotorCalibration](xWalkServoMotorCalibration/xWalkServoMotorCalibration.md):
  servo and motor calibration.
- [xWalkServoZeroing](xWalkServoZeroing/xWalkServoZeroing.md): ordered pulse and zero of servo channels 0–11.

## 5. Public interface

`xWalkDriverCalibration` (alias `xWalk::AgentCalibration`) is a C++17 `INTERFACE` target that links
`xWalkGrayscaleCalibration`, `xWalkServoMotorCalibration`, and `xWalkServoZeroing`.

## 6. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_AGENT_CALIBRATION_BUILD_HOST_TESTS` | `OFF` | Builds the group suite; forces child host tests on |
| `XWALK_AGENT_CALIBRATION_BUILD_HARDWARE_TESTS` | `OFF` | Builds the hardware-profile group suite |

Either option includes `xWalkLibrary/XWalkDependencies.cmake` and requires GoogleTest. The aggregate
[xWalkDriver](../xWalkDriver.md) build sets both options from its host and RPi modes.

## 7. Testing

`xWalkDriverCalibrationGroupHostTest` (labels `host`, `agent-group`) runs one GoogleTest case per child module,
each executing the child host test in an isolated process. The grayscale and servo/motor cases pass a
group-local writable configuration path below `test-data`.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-host --output-on-failure -R xWalkDriverCalibrationGroupHostTest
```

`xWalkDriverCalibrationGroupHardwareTest` (labels `hardware`, `agent-group`) checks the RPi build graph for each
child module. Discover hardware tests with `ctest -N -L hardware`; do not run them without explicit approval
and a confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- [xWalkPicarx](../xWalkVehicle/xWalkPicarx/xWalkPicarx.md) for grayscale and servo/motor calibration.
- [xWalkLibrary Common](../../xWalkLibrary/common/xWalkLibrary%20Common.md) for servo zeroing.
- [xWalk-rpi5-trace](../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) for registered diagnostics.

## 9. Safety and constraints

Calibration moves the drive motors and every connected servo. Raise the wheels for motor verification, clear
every servo mechanism, and keep an immediate power-disconnect path available.

Every Calibration child module owns a registered `RPIAGENT` lifecycle trace. Use the authoritative
[Agent trace table](../xWalkDriver.md#runtime-tracing) to select the identifier for GrayscaleCalibration,
ServoMotorCalibration, or ServoZeroing.

## 10. Related notes

- [xWalkDriver](../xWalkDriver.md)
- [xWalkVehicle](../xWalkVehicle/xWalkVehicle.md)

---

[Previous page](../xWalkDriver.md) · [Chapter index](../../../index.md) · [Next page](xWalkGrayscaleCalibration/xWalkGrayscaleCalibration.md)
