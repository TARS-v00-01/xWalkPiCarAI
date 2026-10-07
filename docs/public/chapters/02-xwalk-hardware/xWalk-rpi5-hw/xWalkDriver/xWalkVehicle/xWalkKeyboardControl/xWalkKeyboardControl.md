<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkKeyboardControl

**2. xWalk hardware &middot; Module 19**

<!-- xwalk-page-header:end -->

# xWalkKeyboardControl

`xWalkKeyboardControl` ports the actuator behavior from upstream `example/3.keyboard_control.py`. It maps
single keys to bounded movement pulses and camera steps on a caller-owned `XWalkPicarx`.

## 1. Overview

`w`, `s`, `a`, and `d` produce 80-percent movement pulses: forward straight, backward straight, forward with
-30 degrees steering, and forward with +30 degrees steering. Each pulse lasts 500 milliseconds and then
commands zero power. `i`, `k`, `l`, and `j` move the camera in five-degree steps (tilt up, tilt down, pan
right, pan left) bounded between minus 30 and plus 30 degrees. Keys are case-insensitive; input that is not
exactly one mapped character is ignored.

The Agent observes caller-owned `XWalkPicarx` and scheduling callbacks. Terminal input must be supplied by the
runtime: enter one key per prompt and use `q` to finish. SIGINT, SIGTERM, cancellation, and destruction stop
the motors. Normal completion through `finish()` also centers all three servos and preserves the upstream
final 200-millisecond delay.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVehicle/xWalkKeyboardControl`
(source directory)

## 3. Directory layout

```text
xWalkKeyboardControl/
    CMakeLists.txt                                  Library, alias, and host test registration
    include/
        xAgent_Rpi5CarKeyboardControl.h             Public key handling and cleanup API
        xAgent_Rpi5CarKeyboardControlTypes.h        Callback aliases and key result type
    src/
        xAgent_Rpi5CarKeyboardControl.cpp           Key mapping, camera bounds, pulse, and centering behavior
        xAgent_Rpi5CarKeyboardControlLifecycle.cpp  Dependency validation, cancellation, and destruction
    test/
        include/                                    Test-local types
        src/xAgent_Rpi5CarKeyboardControlTest.cpp   Device-free Agent behavior verification
```

## 4. Public interface

`xwalk::agent::XWalkKeyboardControl` (non-copyable, non-movable) is constructed from an `XWalkPicarx&`, a callback
context, and required delay and continuation callbacks.

| Member | Behavior |
| --- | --- |
| `handleKey(keyText)` | Applies one key and returns `Handled`, `Ignored`, or `Cancelled` |
| `finish()` | Centers all servos, stops the motors, and waits 200 milliseconds |
| `panAngleDegrees()` | Returns the retained camera-pan angle |
| `tiltAngleDegrees()` | Returns the retained camera-tilt angle |

Movement waits poll cancellation in slices no longer than 20 milliseconds. Destruction latches the
`XWalkPicarx` emergency stop.

## 5. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_KEYBOARD_CONTROL_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |

The module builds `xWalkKeyboardControl` (alias `xWalk::KeyboardControl`) and adds `xWalkPicarx` with its tests
disabled when the target is not already defined.

## 6. Testing

`xWalkKeyboardControlHostTest` (label `host`) uses only an in-memory HAL graph and a writable configuration path
below the build directory's `test-data`:

```bash
ctest --test-dir build-host/cmake --output-on-failure -R xWalkKeyboardControlHostTest
```

No physical keyboard-control test is registered.

## 7. Dependencies

- [xWalkPicarx](../xWalkPicarx/xWalkPicarx.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 8. Safety and constraints

Physical use drives the car and moves the steering and camera servos, so it requires a clear travel area and
an approved Robot HAT setup.

The module emits `RPIAGENT.026` when configured and `RPIAGENT.077` for each bounded key command; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 9. Related notes

- [xWalkVehicle](../xWalkVehicle.md)
- [xWalkMoveExample](../xWalkMoveExample/xWalkMoveExample.md)

---

[Previous page](../xWalkCliffDetection/xWalkCliffDetection.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkLineTracking/xWalkLineTracking.md)
