<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkServoZeroing

**2. xWalk hardware &middot; Module 11**

<!-- xwalk-page-header:end -->

# xWalkServoZeroing

`xWalkServoZeroing` ports `example/servo_zeroing.py` as a hardware-independent Agent. It commands Robot HAT
servo channels 0–11 in order, applies the source 10-degree pulse for 100 milliseconds, returns each channel to
zero for another 100 milliseconds, and then retains the process until cancellation.

## 1. Overview

The Raspberry Pi composition owns the MCU reset plus twelve PWM and Servo objects. The Agent observes only
synchronous angle, delay, and cancellation callbacks. Delays are sliced to at most 20 milliseconds so SIGINT
and SIGTERM remain responsive.

After all twelve channels reach zero, `run()` idles in configurable intervals (default 1,000 milliseconds)
until the continuation callback reports cancellation, then returns `true`. Cancellation during the pulse or
zero phase returns `false`.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkCalibration/xWalkServoZeroing`
(source directory)

## 3. Directory layout

```text
xWalkServoZeroing/
    CMakeLists.txt                                  Library, alias, and host test registration
    include/
        xAgent_Rpi5CarServoZeroingTypes.h           Callback and configuration contracts
        xAgent_Rpi5CarServoZeroing.h                Public coordinator contract
    src/
        xAgent_Rpi5CarServoZeroing.cpp              Ordered pulse, zero, and idle behavior
        xAgent_Rpi5CarServoZeroingLifecycle.cpp     Validation and cancellable timing
    test/
        include/                                    Test-local types
        src/xAgent_Rpi5CarServoZeroingTest.cpp      Device-free source-order verification
```

## 4. Public interface

`xwalk::agent::XWalkServoZeroing` (non-copyable, non-movable) is constructed from a callback context, an
`XWalkServoZeroingCallbacks` table, and an optional `XWalkServoZeroingConfiguration`.

| Member | Behavior |
| --- | --- |
| `run()` | Pulses and zeroes channels 0–11, then idles until cancellation |
| `setCancellation(context, continueOperation)` | Rebinds the non-null cancellation callback and its context |

`XWalkServoZeroingCallbacks` requires `setAngle`, `delay`, and `continueOperation`.
`XAGENT_RPI5CAR_SERVO_ZEROING_CHANNEL_COUNT` is 12.

## 5. Configuration

| Field | Default | Valid range |
| --- | --- | --- |
| `pulseAngleDegrees` | 10.0 | Finite, -90 through 90 degrees |
| `zeroAngleDegrees` | 0.0 | Finite, -90 through 90 degrees |
| `commandDelayMs` | 100 | 1 through 10,000 milliseconds |
| `idleDelayMs` | 1,000 | 1 through 10,000 milliseconds |

Incomplete callbacks or non-finite angles throw an invalid-argument error; out-of-range values throw a range
error.

## 6. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_SERVO_ZEROING_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |

The module builds `xWalkServoZeroing` (alias `xWalk::ServoZeroing`) and adds `xWalkLibraryCommon` when the
target is not already defined.

## 7. Testing

`xWalkServoZeroingHostTest` (label `host`) verifies the source order with in-memory callbacks:

```bash
ctest --test-dir build-host/cmake --output-on-failure -R xWalkServoZeroingHostTest
```

No physical servo-zeroing test is registered.

## 8. Dependencies

- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 9. Safety and constraints

Physical execution can move every connected servo and must be explicitly approved on a safe Robot HAT setup.

The module emits `RPIAGENT.016` when the sequence completes after cancellation; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 10. Related notes

- [xWalkCalibration](../xWalkCalibration.md)
- [xWalkServoMotorCalibration](../xWalkServoMotorCalibration/xWalkServoMotorCalibration.md)
- [xWalkServo](../../../xWalkHal/device/xWalkServo/xWalkServo.md)
- [xWalkBoardControl](../../../xWalkHal/layer1/xWalkBoardControl/xWalkBoardControl.md)

---

[Previous page](../xWalkServoMotorCalibration/xWalkServoMotorCalibration.md) · [Chapter index](../../../../index.md) · [Next page](../../xWalkConnectivity/xWalkConnectivity.md)
