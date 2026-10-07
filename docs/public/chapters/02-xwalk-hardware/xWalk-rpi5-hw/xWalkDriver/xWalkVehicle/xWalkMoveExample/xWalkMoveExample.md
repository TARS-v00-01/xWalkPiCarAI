<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkMoveExample

**2. xWalk hardware &middot; Module 21**

<!-- xwalk-page-header:end -->

# xWalkMoveExample

`xWalkMoveExample` ports the bounded movement sequence from upstream `example/2.move.py` into a reusable Agent.
It drives forward at 30 percent, sweeps steering, stops, then sweeps camera pan and tilt with the original
timing.

## 1. Overview

`run()` performs this sequence:

1. drive forward at 30-percent requested power for 500 milliseconds;
2. sweep steering from 0 to 34, down to -34, and back toward zero degrees in one-degree, 10-millisecond steps;
3. stop the motors and pause for one second;
4. sweep camera pan, then camera tilt, with the same pattern;
5. stop the motors and wait 200 milliseconds.

The Agent observes a caller-owned `XWalkPicarx` and caller-owned scheduling callbacks. Every wait polls
cancellation in slices no longer than 20 milliseconds. Cancellation and destruction perform a best-effort
motor stop by latching the `XWalkPicarx` emergency stop.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVehicle/xWalkMoveExample`
(source directory)

## 3. Directory layout

```text
xWalkMoveExample/
    CMakeLists.txt                                  Library, alias, and host test registration
    include/
        xAgent_Rpi5CarMoveExample.h                 Public coordinator contract
        xAgent_Rpi5CarMoveExampleTypes.h            Delay and continuation callback aliases
    src/
        xAgent_Rpi5CarMoveExample.cpp               Movement and servo sweep sequence
        xAgent_Rpi5CarMoveExampleLifecycle.cpp      Validation, cancellable waits, and emergency stop
    test/
        include/                                    Test-local types
        src/xAgent_Rpi5CarMoveExampleTest.cpp       Deterministic in-memory sequence verification
```

## 4. Public interface

`xwalk::agent::XWalkMoveExample` (non-copyable, non-movable) is constructed from an `XWalkPicarx&`, a callback
context, and required delay and continuation callbacks.

| Member | Behavior |
| --- | --- |
| `run()` | Executes the complete sequence; returns `false` after cancellation |

## 5. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_MOVE_EXAMPLE_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |

The module builds `xWalkMoveExample` (alias `xWalk::MoveExample`) and adds `xWalkPicarx` with its tests disabled
when the target is not already defined.

## 6. Testing

`xWalkMoveExampleHostTest` (label `host`) uses only the deterministic in-memory HAL graph and a writable
configuration path below the build directory's `test-data`:

```bash
ctest --test-dir build-host/cmake --output-on-failure -R xWalkMoveExampleHostTest
```

No physical movement test is registered.

## 7. Dependencies

- [xWalkPicarx](../xWalkPicarx/xWalkPicarx.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 8. Safety and constraints

Running the sequence on Raspberry Pi physically moves the car and all three servos. Provide a clear travel
area, clear servo mechanisms, and an approved Robot HAT setup.

The module emits `RPIAGENT.028` when configured and `RPIAGENT.079` when the motion sequence starts; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 9. Related notes

- [xWalkVehicle](../xWalkVehicle.md)
- [xWalkKeyboardControl](../xWalkKeyboardControl/xWalkKeyboardControl.md)

---

[Previous page](../xWalkLineTracking/xWalkLineTracking.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkObstacleAvoidance/xWalkObstacleAvoidance.md)
