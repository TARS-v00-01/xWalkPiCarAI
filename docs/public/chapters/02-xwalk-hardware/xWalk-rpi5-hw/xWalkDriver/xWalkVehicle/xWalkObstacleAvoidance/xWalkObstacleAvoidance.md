<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkObstacleAvoidance

**2. xWalk hardware &middot; Module 22**

<!-- xwalk-page-header:end -->

# xWalkObstacleAvoidance

`xWalkObstacleAvoidance` ports the decision behavior from upstream `example/4.avoiding_obstacles.py`. One
caller-supplied ultrasonic sample selects a bounded forward, turn, or reverse action on a caller-owned
`XWalkPicarx`.

## 1. Overview

One caller-supplied ultrasonic sample selects straight forward motion at or above 40 centimeters, a
100-millisecond right turn (+30 degrees steering) from 20 through less than 40 centimeters, or a
500-millisecond reverse-left action (-30 degrees steering) below 20 centimeters. All movement uses 50-percent
requested power by default. Waits poll cancellation in slices no longer than 20 milliseconds.

Unlike the Python source, non-finite, zero, timeout, and invalid-pulse results stop the motors instead of
entering the less-than-20-centimeter reverse branch.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVehicle/xWalkObstacleAvoidance`
(source directory)

## 3. Directory layout

```text
xWalkObstacleAvoidance/
    CMakeLists.txt                                    Library, alias, and host test registration
    include/
        xAgent_Rpi5CarObstacleAvoidance.h             Public bounded decision and stop API
        xAgent_Rpi5CarObstacleAvoidanceTypes.h        Callback aliases and decision result type
    src/
        xAgent_Rpi5CarObstacleAvoidance.cpp           Distance bands, vehicle commands, and safety behavior
        xAgent_Rpi5CarObstacleAvoidanceLifecycle.cpp  Dependency validation and cancellation polling
    test/
        include/                                      Test-local types
        src/xAgent_Rpi5CarObstacleAvoidanceTest.cpp   Device-free threshold and cleanup verification
```

## 4. Public interface

`xwalk::agent::XWalkObstacleAvoidance` (non-copyable, non-movable) is constructed from an `XWalkPicarx&`, a
callback context, and required delay and continuation callbacks.

| Member | Behavior |
| --- | --- |
| `step(distanceCm)` | Returns `Forward`, `TurnRight`, `ReverseLeft`, `SensorInvalid`, or `Cancelled` |
| `stop()` | Stops the motors |
| `setMotorPowerPercent(percent)` | Changes the requested power for subsequent steps |

A non-finite or non-positive distance stops the motors and returns `SensorInvalid`. Cancellation stops the
motors. Destruction latches the `XWalkPicarx` emergency stop.

### Runtime motor power

`setMotorPowerPercent(percent)` accepts finite values from 0 through 100 and changes subsequent movement
commands. Invalid values throw without changing the prior setting. The owner must serialize the setter with
driver steps. Controller applies GPB updates on its device-owning worker; MQTT threads never mutate driver
settings. Zero power preserves the mode's sensing and decisions while requesting no motor drive. Existing
stop, sensor-failure, and cancellation behavior remains authoritative.

## 5. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_OBSTACLE_AVOIDANCE_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |

The module builds `xWalkObstacleAvoidance` (alias `xWalk::ObstacleAvoidance`) and adds `xWalkPicarx` with its
tests disabled when the target is not already defined.

## 6. Testing

`xWalkObstacleAvoidanceHostTest` (label `host`) uses only an in-memory HAL graph and a writable configuration
path below the build directory's `test-data`:

```bash
ctest --test-dir build-host/cmake --output-on-failure -R xWalkObstacleAvoidanceHostTest
```

No physical obstacle-avoidance test is registered.

## 7. Dependencies

- [xWalkPicarx](../xWalkPicarx/xWalkPicarx.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 8. Safety and constraints

The runtime must provide foreground start, cancellation, and an immediate motor-stop path. Physical execution
requires a clear reverse path, raised first-run verification where appropriate, and an approved
Raspberry Pi/Robot HAT setup.

The module emits `RPIAGENT.029` when configured and `RPIAGENT.080` on entering the turn response; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 9. Related notes

- [xWalkVehicle](../xWalkVehicle.md)
- [xWalkUltrasonic](../../../xWalkHal/device/xWalkUltrasonic/xWalkUltrasonic.md)

---

[Previous page](../xWalkMoveExample/xWalkMoveExample.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkPicarx/xWalkPicarx.md)
