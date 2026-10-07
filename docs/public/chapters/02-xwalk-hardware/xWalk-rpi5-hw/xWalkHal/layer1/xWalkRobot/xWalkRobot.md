<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkRobot

**2. xWalk hardware &middot; Module 95**

<!-- xwalk-page-header:end -->

# xWalkRobot

`xWalkRobot` is a C++17 coordinator for articulated multi-servo robots. `XWalkRobot` registers up to 12
caller-created `XWalkServo` objects, loads calibration offsets through `XWalkConfigStore`, applies origins and
direction multipliers, interpolates synchronized movements, and stores named actions.

## 1. Overview

Production behavior and host verification use unique trace IDs `RPI.339` through `RPI.356`. The workspace
validator rejects a repeated numeric ID within the `RPI` tag.

Ported behavior:

- Initial logical angles and selectable initialization order
- Persisted `<robot-name>_servo_offset_list` values
- Offset clamping from -20 through 20 degrees
- Raw and origin/direction/offset-adjusted writes
- Speed- or BPM-based synchronized interpolation
- Maximum motion speed of 428 degrees per second
- Named action frames and repetition
- Calibration, reset, and soft-reset behavior

Malformed offset configuration and mismatched frame lengths are rejected with exceptions. At least one
interpolation step is used for very high BPM values, preventing division by zero.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot`
(source directory)

## 3. Directory layout

```text
xWalkRobot/
├── CMakeLists.txt                              Library and host-test targets
├── include/
│   └── xHal_Rpi5CarRobot.h                     Public bounded multi-servo robot API and limits
├── src/
│   ├── xHal_Rpi5CarRobotLifecycle.cpp          Registration, offset parsing, and initialization
│   ├── xHal_Rpi5CarRobotMovement.cpp           Interpolation and named action execution
│   └── xHal_Rpi5CarRobotPosition.cpp           Position transforms, calibration, and resets
├── simulation/                                 Standalone device-free simulation
│   ├── config/xHal_Rpi5CarRobotTraceConfig.py  Persistent trace catalogue generator
│   ├── include/                                Host stub, arguments, configuration, scenario
│   └── src/                                    main.cpp, device-free I2C adapter, and scenario
└── test/
    ├── include/xHal_Rpi5CarRobotTestSupport.h  xwalk::hal::test::robot support declarations
    └── src/
        ├── xHal_Rpi5CarRobotTest.cpp           Simulated host behavior and validation coverage
        └── xHal_Rpi5CarRobotTestSupport.cpp    Named reusable host-test callbacks and state
```

## 4. Child modules

| Note | Description |
|---|---|
| [xWalkRobot Simulation](simulation/xWalkRobot%20Simulation.md) | Device-free standalone simulation |

## 5. Public interface

`xHal_Rpi5CarRobot.h`
declares `XWalkRobot` and the limits `XHAL_RPI5CAR_ROBOT_MAX_SERVOS` (12), `XHAL_RPI5CAR_ROBOT_MAX_DPS` (428.0),
and the offset range `XHAL_RPI5CAR_ROBOT_MIN_OFFSET_DEG` to `XHAL_RPI5CAR_ROBOT_MAX_OFFSET_DEG` (-20.0 to 20.0).

| Group | Members |
|---|---|
| Lifecycle | `addServo()`, `initialize()`, `initialized()`, `servoCount()` |
| Writes | `servoWriteRaw()`, `servoWriteAll()`, `servoMove()` |
| Actions | `setAction()`, `doAction()` |
| Calibration | `setOffsets()`, `setOriginPositions()`, `setCalibrationPositions()`, `setDirections()` |
| Calibration run | `calibration()` |
| Reset | `reset()`, `reset(positions)`, `softReset()` |
| State | `servoPositions()`, `offsets()` |

The constructor takes the store, a non-empty robot name used as the offset-key prefix (default `other`), and an
optional delay in milliseconds between initialization commands.

The application creates dependencies in lifetime order and passes each project object by reference:

```cpp
XWalkConfigStore store("robot.config");
XWalkRobot robot(store, "walker");
robot.addServo(firstServo, 10.0);
robot.addServo(secondServo, -10.0);
robot.initialize();
```

The robot stores non-owning pointers. Registration is separate from initialization so a variable number of servos
can be supplied by reference without transferring ownership or constructing servo objects inside the robot.

## 6. Build

| Option | Default | Effect |
|---|---:|---|
| `XWALK_ROBOT_BUILD_HOST_TESTS` | `OFF` | Builds the Robot host test and the Servo and Config host tests |
| `XWALK_ROBOT_BUILD_HARDWARE_TESTS` | `OFF` | Compiles Servo, PWM, and I2C hardware dependencies; requires Linux |

A standalone build adds `xWalkLibrary/common`, `xWalk-rpi5-trace`, `xWalkServo`, and `xWalkConfig` when their
targets are not already defined. The library compiles with `-Wall -Wextra -Wpedantic -Wconversion
-Wsign-conversion` on GCC and Clang.

## 7. Configuration

Calibration offsets persist in the caller's `XWalkConfigStore` under `<robot-name>_servo_offset_list`. The host
test and simulation generate a persistent trace catalogue with
`simulation/config/xHal_Rpi5CarRobotTraceConfig.py`. For example, `--trace RPI.352.enable` saves the enabled
state, and a later run without a selector loads it automatically. Enabled records appear in both the terminal
and the log.

## 8. Testing

Run from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot/build-host -DXWALK_ROBOT_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot/build-host --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot/build-host --output-on-failure
```

The CTest entry `xWalkRobotHostTest` (label `host`) runs `xWalkRobotTest` with callback-driven I2C simulation and
writes configuration only below the module build directory (`test-data/robot.config`). Reusable callbacks and
state live in `xwalk::hal::test::robot`. In a workspace build the scenarios run in `xGoogleTest` as
`TEST_SUITE_XWALK_ROBOT`.

Hardware compilation without execution:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot/build-rpi -DXWALK_ROBOT_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot/build-rpi --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot/build-rpi -N -L hardware
```

The Robot option compiles Servo, PWM, and I2C hardware targets. It does not register a robot motion test, because
automatically moving an arbitrary articulated robot is not safe without application-specific limits.

## 9. Dependencies

- Public: `xWalkLibraryCommon`, `xWalkServo`, and `xWalkConfig`.
- Private: `xWalkTrace`.
- Host tests: Python 3 for trace-catalogue generation.

## 10. Safety and constraints

- The configuration store and every registered servo must outlive the robot.
- At most 12 servos can be registered, and motion speed is limited to 428 degrees per second.
- Servo hardware tests from the dependent modules move actuators; run them only with explicit approval and a
  confirmed safe Raspberry Pi and Robot HAT setup with mechanical clearance.

## 11. Related notes

- [xWalkHal Layer1](../xWalkHal%20Layer1.md)
- [xWalkHal Layer1 Tests](../test/xWalkHal%20Layer1%20Tests.md)
- [xWalkServo](../../device/xWalkServo/xWalkServo.md)
- [xWalkPwm](../../device/xWalkPwm/xWalkPwm.md)
- [xWalkConfig](../../interface/xWalkConfig/xWalkConfig.md)
- [xWalkHal](../../xWalkHal.md)

---

[Previous page](../xWalkMusic/simulation/xWalkMusic%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkRobot%20Simulation.md)
