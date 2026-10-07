<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkCliffDetection

**2. xWalk hardware &middot; Module 18**

<!-- xwalk-page-header:end -->

# xWalkCliffDetection

`xWalkCliffDetection` ports the state machine from upstream `example/5.cliff_detection.py`. Each bounded step
reads all three grayscale channels and either stops the motors or reverses away from a detected cliff.

## 1. Overview

A safe result stops the motors; a cliff result reverses at 80-percent requested power and waits
100 milliseconds only on a safe-to-danger transition. The wait polls cancellation in slices no longer than
20 milliseconds.

The Agent uses the active persisted `cliff_reference` values. It deliberately does not overwrite calibrated
references with the Python example's illustrative `[200,200,200]` values. Run
[grayscale calibration](../../xWalkCalibration/xWalkGrayscaleCalibration/xWalkGrayscaleCalibration.md) before
physical use.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVehicle/xWalkCliffDetection`
(source directory)

## 3. Directory layout

```text
xWalkCliffDetection/
    CMakeLists.txt                                  Library, alias, and host test registration
    include/
        xAgent_Rpi5CarCliffDetection.h              Public bounded step and stop API
        xAgent_Rpi5CarCliffDetectionTypes.h         Callback aliases and step result type
    src/
        xAgent_Rpi5CarCliffDetection.cpp            Grayscale sampling and safe/danger state machine
        xAgent_Rpi5CarCliffDetectionLifecycle.cpp   Dependency validation and cancellation polling
    test/
        include/                                    Test-local types
        src/xAgent_Rpi5CarCliffDetectionTest.cpp    Device-free state-transition verification
```

## 4. Public interface

`xwalk::agent::XWalkCliffDetection` (non-copyable, non-movable) is constructed from an `XWalkPicarx&`, a callback
context, and required delay and continuation callbacks.

| Member | Behavior |
| --- | --- |
| `step()` | Samples once and returns `Safe`, `Danger`, or `Cancelled` |
| `stop()` | Stops the motors |
| `lastDanger()` | Reports whether the previous step detected a cliff |
| `setMotorPowerPercent(percent)` | Changes the reverse power for subsequent steps |

Cancellation stops the motors and returns `Cancelled`. Destruction latches the `XWalkPicarx` emergency stop.

### Runtime motor power

`setMotorPowerPercent(percent)` accepts finite values from 0 through 100 and changes subsequent movement
commands. Invalid values throw without changing the prior setting. The owner must serialize the setter with
driver steps. Controller applies GPB updates on its device-owning worker; MQTT threads never mutate driver
settings. Zero power preserves the mode's sensing and decisions while requesting no motor drive. Existing
stop, sensor-failure, and cancellation behavior remains authoritative.

## 5. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_CLIFF_DETECTION_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |

The module builds `xWalkCliffDetection` (alias `xWalk::CliffDetection`) and adds `xWalkPicarx` with its tests
disabled when the target is not already defined.

## 6. Testing

`xWalkCliffDetectionHostTest` (label `host`) uses only an in-memory HAL graph and a writable configuration path
below the build directory's `test-data`:

```bash
ctest --test-dir build-host/cmake --output-on-failure -R xWalkCliffDetectionHostTest
```

No physical cliff-detection test is registered.

## 7. Dependencies

- [xWalkPicarx](../xWalkPicarx/xWalkPicarx.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 8. Safety and constraints

The runtime must provide foreground start, cancellation, and an immediate motor-stop path. Physical execution
requires calibrated references and a protected test area where reverse motion cannot drive the vehicle off
another edge.

The module emits `RPIAGENT.025` when configured and `RPIAGENT.076` on entering the danger response; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 9. Related notes

- [xWalkVehicle](../xWalkVehicle.md)
- [xWalkLineTracker](../../../xWalkHal/sensor/xWalkLineTracker/xWalkLineTracker.md)

---

[Previous page](../xWalkVehicle.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkKeyboardControl/xWalkKeyboardControl.md)
