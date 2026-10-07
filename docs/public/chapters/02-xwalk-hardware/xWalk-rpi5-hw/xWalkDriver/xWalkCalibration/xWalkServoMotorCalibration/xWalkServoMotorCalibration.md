<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) /
xWalkServoMotorCalibration

**2. xWalk hardware &middot; Module 10**

<!-- xwalk-page-header:end -->

# xWalkServoMotorCalibration

`xWalkServoMotorCalibration` is the Agent-level port of the supplied `picar-x/example/1.cali_servo_motor.py`
helper. It stores pending servo offsets and motor directions around a caller-owned `XWalkPicarx`; Linux
devices, terminal input, and operator policy remain outside the module.

## 1. Overview

The port provides:

- source-compatible servo reset and nine-position servo test sequences;
- pending steering, camera-pan, and camera-tilt offsets bounded to ±20 degrees;
- motor-direction preview and source-compatible 30-percent forward testing;
- explicit persistence of all pending values through `save()`;
- cancellation polling in slices no longer than 20 milliseconds;
- best-effort motor cleanup on cancellation and destruction.

The reset sequence centers servos 0, 1, and 2 with a 200-millisecond wait after each. The test sequence moves
each servo to -30, +30, and zero degrees with a 500-millisecond wait after each position. Offsets and
directions are applied as non-persistent `XWalkPicarx` previews until `save()` is called.

The replacement runtime must compose this Agent with prompts, motor-balance configuration, raised-wheel
verification, and final persistence confirmation.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkCalibration/xWalkServoMotorCalibration`
(source directory)

## 3. Directory layout

```text
xWalkServoMotorCalibration/
    CMakeLists.txt                                     Library, alias, and host test registration
    include/
        xAgent_Rpi5CarServoMotorCalibration.h          Public coordinator contract
        xAgent_Rpi5CarServoMotorCalibrationTypes.h     Delay and continuation callbacks, result structure
    src/
        xAgent_Rpi5CarServoMotorCalibration.cpp        Servo sequences, offsets, motor directions, and save
        xAgent_Rpi5CarServoMotorCalibrationLifecycle.cpp  Validation, cancellable waits, and cleanup
    test/
        include/                                       Test-local types
        src/                                           Device-free host test
```

## 4. Public interface

`xwalk::agent::XWalkServoMotorCalibration` (non-copyable, non-movable) is constructed from an `XWalkPicarx&`, a
callback context, and required delay and continuation callbacks.

| Member | Behavior |
| --- | --- |
| `resetServos()` | Centers servos 0 (steering), 1 (camera pan), and 2 (camera tilt) |
| `testServos()` | Runs the nine-position test sequence |
| `setServoOffset(servoId, offsetDegrees)` | Stores and previews a finite offset from -20 through 20 degrees |
| `setMotorDirection(motorId, direction)` | Stores and previews the direction of motor 1 or 2 |
| `toggleMotorDirection(motorId)` | Inverts the pending direction and runs the motors forward |
| `setMotorRunning(running)` | Drives forward at 30 percent or stops |
| `save()` | Persists all pending offsets and directions through `XWalkPicarx` |
| `result()` | Returns the pending `XWalkServoMotorCalibrationResult` |

Invalid identifiers or offsets throw through the project error macros. Sequences return `false` after
cancellation.

## 5. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_SERVO_MOTOR_CALIBRATION_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |

The module builds `xWalkServoMotorCalibration` (alias `xWalk::ServoMotorCalibration`) and adds `xWalkPicarx`
with its tests disabled when the target is not already defined.

## 6. Testing

`xWalkServoMotorCalibrationHostTest` (label `host`) receives a writable configuration path below the build
directory's `test-data`. From `xWalk-rpi5-hw`, after `cmake --preset host-debug`:

```bash
cmake --build --preset host-debug --target xWalkServoMotorCalibrationTest --parallel
```

```bash
ctest --preset host-debug -R xWalkServoMotorCalibrationHostTest
```

No physical calibration test is registered.

## 7. Dependencies

- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 8. Safety and constraints

Physical execution moves all three servos and can run both motors. Raise the wheels for motor verification,
clear every servo mechanism, and keep an immediate power-disconnect path available.

The module emits `RPIAGENT.023` when configured; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 9. Related notes

- [xWalkCalibration](../xWalkCalibration.md)
- [xWalkServoZeroing](../xWalkServoZeroing/xWalkServoZeroing.md)
- [xWalkServo](../../../xWalkHal/device/xWalkServo/xWalkServo.md)
- [xWalkMotor](../../../xWalkHal/sensor/xWalkMotor/xWalkMotor.md)

---

[Previous page](../xWalkGrayscaleCalibration/xWalkGrayscaleCalibration.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkServoZeroing/xWalkServoZeroing.md)
