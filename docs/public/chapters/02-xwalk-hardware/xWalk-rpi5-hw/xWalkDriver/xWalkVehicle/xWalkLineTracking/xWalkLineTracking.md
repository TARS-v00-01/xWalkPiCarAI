<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkLineTracking

**2. xWalk hardware &middot; Module 20**

<!-- xwalk-page-header:end -->

# xWalkLineTracking

`xWalkLineTracking` is a C++17 Agent submodule that ports `example/6.line_tracking.py` into forward, left,
right, and line-lost recovery commands while keeping sensor, motor, servo, configuration, scheduling, and
diagnostic ownership outside the module.

## 1. Overview

- preserves the upstream status priority: all background means stop, then middle means forward, left sensor
  means right, and right sensor means left;
- preserves default forward power 10 percent, steering offset 20 degrees, reverse-recovery power 10 percent,
  reverse-recovery steering 30 degrees, and the one-millisecond post-recovery delay;
- retains the last non-stop direction to choose the upstream reverse-recovery steering sign;
- exposes one deterministic `step()` while the application owns repeated scheduling and cancellation;
- returns the final grayscale readings, decision, recovery-attempt flag, and recovery-timeout flag so the
  application can provide the example's console diagnostics;
- injects timing and stores only a non-owning pointer to caller-created `XWalkPicarx`;
- stops the motors when destroyed or explicitly stopped;
- exposes `finish()` to preserve the source example's final 100-millisecond delay after stopping.

Recovery is bounded to at most 100,000 configured samples and stops on timeout or when recovery has no
directional history. Applications select their own repeated scheduling and cancellation policy.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVehicle/xWalkLineTracking`
(source directory)

## 3. Directory layout

```text
xWalkLineTracking/
    CMakeLists.txt                                  Library, alias, and host test registration
    include/
        xAgent_Rpi5CarLineTracking.h                Step, classification, recovery, and dependency contract
        xAgent_Rpi5CarLineTrackingTypes.h           State, configuration, timing callback, and step result
    src/
        xAgent_Rpi5CarLineTracking.cpp              Classification, movement, sampling, and bounded recovery
        xAgent_Rpi5CarLineTrackingLifecycle.cpp     Configuration validation, stop, and retained state
    test/
        include/                                    Test-local types
        src/xAgent_Rpi5CarLineTrackingTest.cpp      In-memory state, movement, recovery, and validation tests
```

## 4. Public interface

`xwalk::agent::XWalkLineTracking` is constructed from an `XWalkPicarx&`, a callback context, a required delay
callback, and an optional `XWalkLineTrackingConfiguration`.

| Member | Behavior |
| --- | --- |
| `classify(status)` | Static mapping of a line-tracker status to `Stop`, `Forward`, `Left`, or `Right` |
| `step()` | Samples, moves, and recovers once; returns `XWalkLineTrackingResult` |
| `stop()` | Stops the motors and clears current and last states |
| `finish()` | Stops and waits 100 milliseconds |
| `currentState()` / `lastState()` | Return the retained states |
| `setMotorPowerPercent(percent)` | Changes forward and recovery power |

### Runtime motor power

`setMotorPowerPercent(percent)` accepts finite values from 0 through 100 and changes subsequent movement
commands. Invalid values throw without changing the prior setting. The owner must serialize the setter with
driver steps. Controller applies GPB updates on its device-owning worker; MQTT threads never mutate driver
settings. Zero power preserves the mode's sensing and decisions while requesting no motor drive. Existing
stop, sensor-failure, and cancellation behavior remains authoritative. The setting applies to both forward
tracking and reverse recovery.

## 5. Configuration

| Field | Default | Valid range |
| --- | --- | --- |
| `powerPercent` | 10.0 | Finite, 0 through 100 |
| `steeringOffsetDegrees` | 20.0 | Finite, 0 through 30 |
| `recoverySteeringDegrees` | 30.0 | Finite, 0 through 30 |
| `recoveryPowerPercent` | 10.0 | Finite, 0 through 100 |
| `maximumRecoverySamples` | 1,000 | 1 through 100,000 |
| `recoveryCompletionDelayMs` | 1 | At most 1,000 milliseconds |

Calibrate `line_reference` in the PiCar-X configuration for the actual surface before enabling motion.

## 6. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_LINE_TRACKING_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |
| `XWALK_LINE_TRACKING_BUILD_HARDWARE_TESTS` | `OFF` | Compiles with Linux/RPi dependencies; Linux only |

The module builds `xWalkLineTracking` (alias `xWalk::LineTracking`). When `xWalkPicarx` is not already defined,
it is added with host tests off and its hardware tests following the line-tracking hardware option.

## 7. Testing

`xWalkLineTrackingHostTest` (label `host`) receives a writable configuration path below the build directory's
`test-data`:

```bash
ctest --test-dir build-host/cmake --output-on-failure -R xWalkLineTrackingHostTest
```

`XWALK_LINE_TRACKING_BUILD_HARDWARE_TESTS=ON` only compiles the module and its Linux/RPi dependencies. No
physical line-following test is registered because unattended drive motion is unsafe.

## 8. Dependencies

- [xWalkPicarx](../xWalkPicarx/xWalkPicarx.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 9. Safety and constraints

Calibrate `line_reference` for the actual surface before enabling motion. Start with the wheels lifted, use
low power, keep the steering and camera mechanisms clear, and call `finish()` when application scheduling
ends. Do not run the physical gesture or line-tracking path through ordinary host verification.

The module emits `RPIAGENT.027` when configured and `RPIAGENT.078` for recovery events; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 10. Related notes

- [xWalkVehicle](../xWalkVehicle.md)
- [xWalkGrayscaleCalibration](../../xWalkCalibration/xWalkGrayscaleCalibration/xWalkGrayscaleCalibration.md)
- [xWalkLineTracker](../../../xWalkHal/sensor/xWalkLineTracker/xWalkLineTracker.md)

---

[Previous page](../xWalkKeyboardControl/xWalkKeyboardControl.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkMoveExample/xWalkMoveExample.md)
