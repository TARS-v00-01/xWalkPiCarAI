<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkVehicle

**2. xWalk hardware &middot; Module 17**

<!-- xwalk-page-header:end -->

# xWalkVehicle

`xWalkVehicle` is the Vehicle functional group of the xWalk Agent layer. It groups the movement and autonomous
vehicle coordinators behind the `xWalk::AgentVehicle` interface target.

## 1. Overview

The group owns the `xWalkPicarx`, `xWalkLineTracking`, `xWalkMoveExample`, `xWalkKeyboardControl`,
`xWalkObstacleAvoidance`, `xWalkCliffDetection`, and `xWalkSelfDrive` module directories. Every child remains an
independent CMake target with its existing public headers, ownership rules, and host or hardware verification
boundary. `xWalkPicarx` is the shared PiCar-X coordinator that every other Vehicle module observes.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVehicle`
(source directory)

## 3. Directory layout

```text
xWalkVehicle/
    CMakeLists.txt                  Group options, xWalk::AgentVehicle target, and group test registration
    test/
        src/                        xWalkDriverVehicleGroupTest host suite
        hardware/src/               xWalkDriverVehicleGroupHardwareTest hardware-profile suite
    xWalkPicarx/                    Shared PiCar-X coordinator and persisted calibration
    xWalkLineTracking/              Line following with bounded recovery
    xWalkMoveExample/               Bounded movement and servo sweep sequence
    xWalkKeyboardControl/           Key-driven movement pulses and camera steps
    xWalkObstacleAvoidance/         Ultrasonic distance-band decisions
    xWalkCliffDetection/            Grayscale cliff detection and reverse response
    xWalkSelfDrive/                 Named preset actions, sounds, and action queue worker
```

## 4. Child modules

| Note | Responsibility |
| --- | --- |
| [xWalkPicarx](xWalkPicarx/xWalkPicarx.md) | Motors, servos, sensors, calibration, emergency stop |
| [xWalkLineTracking](xWalkLineTracking/xWalkLineTracking.md) | Three-channel line following and recovery |
| [xWalkMoveExample](xWalkMoveExample/xWalkMoveExample.md) | `example/2.move.py` sequence |
| [xWalkKeyboardControl](xWalkKeyboardControl/xWalkKeyboardControl.md) | `example/3.keyboard_control.py` |
| [xWalkObstacleAvoidance](xWalkObstacleAvoidance/xWalkObstacleAvoidance.md) | `example/4.avoiding_obstacles.py` |
| [xWalkCliffDetection](xWalkCliffDetection/xWalkCliffDetection.md) | `example/5.cliff_detection.py` |
| [xWalkSelfDrive](xWalkSelfDrive/xWalkSelfDrive.md) | Preset gestures, sounds, music, and worker queue |

## 5. Public interface

`xWalkDriverVehicle` (alias `xWalk::AgentVehicle`) is a C++17 `INTERFACE` target that links all seven child
module libraries.

## 6. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_AGENT_VEHICLE_BUILD_HOST_TESTS` | `OFF` | Builds the group suite; forces child host tests on |
| `XWALK_AGENT_VEHICLE_BUILD_HARDWARE_TESTS` | `OFF` | Builds the hardware-profile group suite |

Either option includes `xWalkLibrary/XWalkDependencies.cmake` and requires GoogleTest.

## 7. Testing

`xWalkDriverVehicleGroupHostTest` (labels `host`, `agent-group`) runs one GoogleTest case per child module, each
executing the child host test in an isolated process with a group-local writable configuration.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-host --output-on-failure -R xWalkDriverVehicleGroupHostTest
```

`xWalkDriverVehicleGroupHardwareTest` (labels `hardware`, `agent-group`) checks the RPi build graph for each
child. Discover hardware tests with `ctest -N -L hardware`; do not run them without explicit approval and a
confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- [xWalkHal](../../xWalkHal/xWalkHal.md) motor, servo, line-tracker, ultrasonic, configuration, and music
  modules.
- [xWalk-rpi5-trace](../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) registered diagnostics.

## 9. Safety and constraints

Every Vehicle child can move the drive motors or servos. Lift the wheels for first runs, keep the steering and
camera mechanisms clear, and provide an immediate motor-stop path.

Every Vehicle child module owns a registered `RPIAGENT` lifecycle or bounded-action trace. Use the
authoritative [Agent trace table](../xWalkDriver.md#runtime-tracing) to select one child. Repeated control-loop
samples and fail-safe cleanup remain trace-free.

## 10. Related notes

- [xWalkDriver](../xWalkDriver.md)
- [xWalkCalibration](../xWalkCalibration/xWalkCalibration.md)

---

[Previous page](../xWalkMedia/xWalkSoundBackgroundMusic/xWalkSoundBackgroundMusic.md) · [Chapter index](../../../index.md) · [Next page](xWalkCliffDetection/xWalkCliffDetection.md)
