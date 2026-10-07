<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) /
xWalkGrayscaleCalibration

**2. xWalk hardware &middot; Module 09**

<!-- xwalk-page-header:end -->

# xWalkGrayscaleCalibration

`xWalkGrayscaleCalibration` is the Agent-level port of the supplied `picar-x/example/1.cali_grayscale.py`
helper. It calibrates the line and cliff references of the three-channel grayscale module through a
caller-owned `XWalkPicarx` coordinator.

## 1. Overview

The coordinator composes a caller-owned `XWalkPicarx` with injected timing and cancellation callbacks; it does
not own Linux devices or terminal input. The bounded synchronous port preserves these source behaviors:

- steering verification at -30, +30, and zero degrees;
- automatic line-reference sampling while driving the left and right calibration pattern;
- per-channel midpoint calculation from observed minima and maxima;
- stationary cliff-reference averaging and source-compatible threshold adjustment;
- pending values that are persisted only through an explicit `save()` call;
- best-effort motor stop and centered steering after cancellation or destruction.

The Python worker threads are intentionally represented as deterministic 200-millisecond sampling steps. Each
wait polls cancellation in slices no longer than 20 milliseconds. Applications remain responsible for
interactive prompts and explicit operator confirmation. The replacement runtime must provide that application
boundary before physical calibration is enabled.

The cliff calculation uses exactly ten samples; the supplied Python loop accumulates eleven samples but divides
by ten, which is treated as an upstream off-by-one defect rather than calibration behavior to preserve.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkCalibration/xWalkGrayscaleCalibration`
(source directory)

## 3. Directory layout

```text
xWalkGrayscaleCalibration/
    CMakeLists.txt                                  Library, alias, and host test registration
    include/
        xAgent_Rpi5CarGrayscaleCalibration.h        Public coordinator contract
        xAgent_Rpi5CarGrayscaleCalibrationTypes.h   Delay and continuation callbacks, result structure
    src/
        xAgent_Rpi5CarGrayscaleCalibration.cpp      Steering check, line sampling, and cliff averaging
        xAgent_Rpi5CarGrayscaleCalibrationLifecycle.cpp  Validation, cancellable waits, stop, and save
    test/
        include/                                    Test-local types
        src/                                        Device-free host test
```

## 4. Public interface

`xwalk::agent::XWalkGrayscaleCalibration` (non-copyable, non-movable) is constructed from an
`XWalkPicarx&`, a callback context, a delay callback, and a continuation callback; both callbacks are
required.

| Member | Behavior |
| --- | --- |
| `runSteeringCheck()` | Steers to -30, +30, and zero degrees |
| `calibrateLine()` | Drives the calibration pattern and stores per-channel midpoints |
| `calibrateCliff()` | Averages ten stationary samples into the pending cliff reference |
| `save()` | Persists pending line and cliff references through `XWalkPicarx` |
| `result()` | Returns the pending `XWalkGrayscaleCalibrationResult` |

Operations return `false` after cancellation. `XWalkGrayscaleCalibrationResult` defaults to a line reference
of `[1000, 1000, 1000]` and a cliff reference of `[500, 500, 500]`.

## 5. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_GRAYSCALE_CALIBRATION_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |

The module builds `xWalkGrayscaleCalibration` (alias `xWalk::GrayscaleCalibration`) and adds `xWalkPicarx` with
its tests disabled when the target is not already defined.

## 6. Testing

`xWalkGrayscaleCalibrationHostTest` (label `host`) receives a writable configuration path below the build
directory's `test-data`. From `xWalk-rpi5-hw`, after `cmake --preset host-debug`:

```bash
cmake --build --preset host-debug --target xWalkGrayscaleCalibrationTest --parallel
```

```bash
ctest --preset host-debug -R xWalkGrayscaleCalibrationHostTest
```

No physical calibration test is registered.

## 7. Dependencies

- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 8. Safety and constraints

The line-calibration operation moves the drive motors. Physical use requires a clear reviewed surface,
correct Raspberry Pi and Robot HAT wiring, and explicit operator approval.

The module emits `RPIAGENT.022` when configured and `RPIAGENT.045` when the line-calibration motion sequence
starts; see the [Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 9. Related notes

- [xWalkCalibration](../xWalkCalibration.md)
- [xWalkCliffDetection](../../xWalkVehicle/xWalkCliffDetection/xWalkCliffDetection.md)
- [xWalkLineTracking](../../xWalkVehicle/xWalkLineTracking/xWalkLineTracking.md)
- [xWalkLineTracker](../../../xWalkHal/sensor/xWalkLineTracker/xWalkLineTracker.md)

---

[Previous page](../xWalkCalibration.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkServoMotorCalibration/xWalkServoMotorCalibration.md)
