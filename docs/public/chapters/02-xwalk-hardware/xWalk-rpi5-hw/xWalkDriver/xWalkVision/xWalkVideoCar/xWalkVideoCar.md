<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkVideoCar

**2. xWalk hardware &middot; Module 32**

<!-- xwalk-page-header:end -->

# xWalkVideoCar

`xWalkVideoCar` ports upstream `example/11.video_car.py` behind the existing PiCar-X and computer-vision
interfaces. It preserves the interactive speed, motion, steering, photo, warm-up, and per-key delay behavior.

## 1. Overview

The Agent maps single-key commands to PiCar-X motion and to photo capture through the computer-vision provider
callbacks. It deliberately does not start Vilib's implicit web display server. Camera acquisition and
timestamped photo storage are supplied by the existing computer-vision provider.

The Agent accepts `o`, `p`, `w`, `s`, `a`, `d`, `f`, and `t`, matched case-insensitively; any other key is
ignored. Every key is followed by a cancellable delay, and cancellation stops the motors.

| Key | Effect |
| --- | --- |
| `o` | Raise speed by one step, up to the maximum |
| `p` | Lower speed by one step; reaching 0 percent stops the car |
| `w` | Drive forward with straight steering |
| `s` | Drive backward with straight steering |
| `a`, `d` | Steer left or right by the configured angle and drive forward |
| `f` | Stop |
| `t` | Capture a photo through the provider and return its path |

Speed changes reapply the current motion. Starting a motion at 0 percent first selects one speed step.
Selecting `w` or `s` from any other motion caps the speed at the configured direction-change limit.

The Controller boot composition root
(`xControllerBootModules.cpp`)
constructs the Agent with the
PiCar-X object and the computer-vision provider callbacks.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkVideoCar` (source
directory,
CMakeLists.txt)

## 3. Directory layout

```text
xWalkVideoCar/
    CMakeLists.txt                               Static library and dependency wiring
    include/
        xAgent_Rpi5CarVideoCarTypes.h            Motion, event, configuration, and result contracts
        xAgent_Rpi5CarVideoCar.h                 Public interactive video-car class
    src/
        xAgent_Rpi5CarVideoCar.cpp               Key handling, motion application, and motion names
        xAgent_Rpi5CarVideoCarLifecycle.cpp      Validation, startup warm-up, cancellable delay, and cleanup
```

The module has no own test directory; it is covered by the vision group tests described below.

## 4. Public interface

Public headers are in the module
`include` directory.

- `xAgent_Rpi5CarVideoCar.h` declares the non-copyable, non-movable `xwalk::agent::XWalkVideoCar`. The
  constructor takes a PiCar-X reference, a non-owning callback context, `XWalkComputerVisionCallbacks`, and an
  optional configuration. The PiCar-X reference is stored as a non-owning pointer and must outlive the Agent.
- `xAgent_Rpi5CarVideoCarTypes.h` defines `XWalkVideoCarMotion` (`Stop`, `Forward`, `Backward`, `TurnLeft`,
  `TurnRight`), `XWalkVideoCarEvent` (`Ignored`, `MotionChanged`, `SpeedChanged`, `PhotoCaptured`,
  `Cancelled`), `XWalkVideoCarConfiguration`, and `XWalkVideoCarResult`.

| Member | Behavior |
| --- | --- |
| `start()` | Resets motion and speed, starts the provider, and waits the warm-up; idempotent |
| `handleKey(key)` | Applies one key and returns the event, motion, speed, and optional photo path |
| `finish()` | Stops the motors and the provider, then resets motion and speed; idempotent |
| `started()` | Reports whether the provider is active |
| `motionName(motion)` | Returns a lowercase motion name such as `forward` |

`handleKey()` throws a logic error before `start()`. An interrupted warm-up stops the car and the provider and
makes `start()` return false.

## 5. Build

The CMake project defines the static library `xWalkVideoCar` with alias `xWalk::VideoCar` (C++17). It links
`xWalkPicarx` and `xWalkComputerVision` publicly and `xWalkTrace` privately. When built standalone, it adds
missing dependency targets with their host, OpenCV, and hardware test options forced off. GNU and Clang builds use
`-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`.

The module defines no CMake option of its own. In the workspace build it is part of the `xWalk::AgentVision`
interface target.

## 6. Configuration

`XWalkVideoCarConfiguration` is validated at construction. Missing callbacks or a non-finite steering angle raise
an invalid-argument error; out-of-range values raise a range error.

| Field | Default | Valid range |
| --- | --- | --- |
| `speedStepPercent` | 10 | 1 to `maximumSpeedPercent` |
| `maximumSpeedPercent` | 100 | at most 100 percent |
| `directionChangeCapPercent` | 60 | at most `maximumSpeedPercent` |
| `steeringAngleDegrees` | 30.0 | finite, greater than 0 to 45 degrees |
| `startupDelayMs` | 2000 | 0 to 10000 milliseconds |
| `keyDelayMs` | 100 | 1 to 1000 milliseconds |

The provider callbacks `start`, `stop`, `capture`, `delay`, and `continueOperation` are required. Delays are
polled for cancellation in slices of at most 20 milliseconds.

## 7. Testing

Host coverage is provided by the vision group test `xWalkDriverVisionGroupHostTest` (labels `host` and
`agent-group`). It checks `motionName()`, the default configuration, and every key and lifecycle state with
simulated PiCar-X and vision callbacks. From the repository root:

```bash
cmake -S xWalk-rpi5-hw --preset host-debug
```

```bash
cmake --build build-host/cmake --target xWalkDriverVisionGroupTest
```

```bash
ctest --test-dir build-host/cmake -R xWalkDriverVisionGroupHostTest --output-on-failure
```

The hardware-profile group test `xWalkDriverVisionGroupHardwareTest` only checks that the class is available.
List hardware tests with `ctest -N -L hardware`; run them only with explicit approval and a confirmed safe
Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- `xWalkPicarx` for steering and drive commands;
- `xWalkComputerVision` for the camera provider callbacks and photo capture;
- `xWalkTrace` for trace and error reporting.

## 9. Safety and constraints

- Motion commands drive the physical car until another key, `f`, cancellation, or `finish()` stops it.
- Speed never exceeds `maximumSpeedPercent`; entering forward or backward motion is capped at
  `directionChangeCapPercent`.
- The Agent does not own or release the PiCar-X object or the provider context.

## 10. Related notes

- [xWalkVision](../xWalkVision.md)
- [xWalkComputerVision](../xWalkComputerVision/xWalkComputerVision.md)
- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md)

---

[Previous page](../xWalkTreasureHunt/xWalkTreasureHunt.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkVideoRecording/xWalkVideoRecording.md)
