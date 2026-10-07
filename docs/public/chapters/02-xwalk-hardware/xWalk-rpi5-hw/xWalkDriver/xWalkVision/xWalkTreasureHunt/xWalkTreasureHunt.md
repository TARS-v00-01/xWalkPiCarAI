<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkTreasureHunt

**2. xWalk hardware &middot; Module 31**

<!-- xwalk-page-header:end -->

# xWalkTreasureHunt

`xWalkTreasureHunt` is a hardware-independent Agent that ports upstream `example/20.treasure_hunt.py`. It asks
the operator to find a randomly selected color, recognizes a sufficiently large color detection, and drives the
PiCar-X in bounded, cancellable movement steps.

## 1. Overview

The Agent preserves the upstream game behavior:

- six selectable target colors: red, orange, yellow, green, blue, and purple;
- a success threshold of a detection wider than 100 pixels;
- spoken prompts `Game start!`, `Look for <color>!`, `Well done!`, and `Goodbye!`;
- an 80-percent requested drive power and minus/plus 30-degree steering for turns;
- bounded half-second motion for each `w`, `a`, `s`, or `d` key, followed by a motor stop;
- space-key repetition of the current target and deterministic cleanup.

The Agent owns no camera, random generator, speech provider, PiCar-X hardware, keyboard thread, or console. The
composition root supplies those services and retains them until the Agent is destroyed. Every delay polls
cancellation in slices no longer than 20 milliseconds, and every movement ends with a motor stop.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkTreasureHunt` (source
directory,
CMakeLists.txt)

## 3. Directory layout

```text
xWalkTreasureHunt/
    CMakeLists.txt                                  Static library and dependency wiring
    include/
        xAgent_Rpi5CarTreasureHuntTypes.h           Callback, configuration, action, and result contracts
        xAgent_Rpi5CarTreasureHunt.h                Public coordinator class
    src/
        xAgent_Rpi5CarTreasureHunt.cpp              Detection, key handling, movement, power, color naming
        xAgent_Rpi5CarTreasureHuntLifecycle.cpp     Validation, startup, cancellable timing, and cleanup
```

The module has no own test directory; it is covered by the vision group tests described below.

## 4. Public interface

Public headers are in the module
`include` directory.

- `xAgent_Rpi5CarTreasureHunt.h` declares the non-copyable, non-movable `xwalk::agent::XWalkTreasureHunt`.
  The constructor takes a PiCar-X reference, a `hal::XWalkTextToSpeech` reference, a non-owning callback
  context, the callback table, and an optional configuration. Both references are stored as non-owning
  pointers and must outlive the Agent.
- `xAgent_Rpi5CarTreasureHuntTypes.h` defines `XWalkTreasureHuntCallbacks` (computer-vision callbacks plus a
  `selectColor` callback), `XWalkTreasureHuntConfiguration`, `XWalkTreasureHuntAction` (`Ignored`, `Moved`,
  `TargetRepeated`, `Quit`, `Cancelled`), and `XWalkTreasureHuntResult`.

| Member | Behavior |
| --- | --- |
| `start(announceTargets = true)` | Starts vision, waits the warm-up, optionally speaks, and selects a target |
| `step(key)` | Checks the target, then handles one key: `w`/`a`/`s`/`d`, `space`, `quit`, or `exit` |
| `finish()` | Stops active vision and motion; optional goodbye speech and final delay |
| `setMotorPowerPercent(percent)` | Changes the requested drive power for subsequent movement |
| `targetColor()`, `started()` | Report the current target and the vision-provider state |
| `colorName(color)` | Returns the lowercase display name; throws for `Close` or an invalid color |

Keys are matched case-insensitively. `step()` throws a logic error when the Agent is not started.

### Lifecycle

Startup returns false for a camera-provider startup failure. Interrupted warm-up or prompt delay stops vision and
throws the shared `hal::XWalkOperationCancelled` control outcome, so the Controller does not misreport it as a
failed startup. `finish()` always stops active vision and motion; goodbye speech and its final delay run only
while the continuation callback permits them and target announcements are enabled. Normal completion preserves
the goodbye. Real speech or provider failures remain failures even when STOP is pending.

`start(false)` disables synchronous speech and prompt delays for a remote control owner. The default `start()`
retains spoken prompts. Target detection and motor safety checks are unchanged.

### Runtime motor power

`setMotorPowerPercent(percent)` accepts finite values from 0 through 100 and changes subsequent movement commands.
Invalid values throw a range error without changing the prior setting. The owner must serialize the setter with
driver steps. Controller applies GPB updates on its device-owning worker; MQTT threads never mutate driver
settings. Zero power preserves the mode's sensing and decisions while requesting no motor drive. Existing stop,
sensor-failure, and cancellation behavior remains authoritative.

## 5. Build

The CMake project defines the static library `xWalkTreasureHunt` with alias `xWalk::TreasureHunt` (C++17). It
links `xWalkPicarx`, `xWalkComputerVision`, and `xWalkGPT` publicly and `xWalkTrace` privately. When built
standalone, it adds missing dependency targets with their host, OpenCV, and hardware test options forced off.
GNU and Clang builds use `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`.

The module defines no CMake option of its own. In the workspace build it is part of the
`xWalk::AgentVision` interface target.

## 6. Configuration

`XWalkTreasureHuntConfiguration` is validated at construction. Invalid callbacks or non-finite values raise an
invalid-argument error; out-of-range values raise a range error.

| Field | Default | Valid range |
| --- | --- | --- |
| `detectionWidthThresholdPixels` | 100 | 1 to 7680 pixels |
| `driveSpeedPercent` | 80.0 | finite, 0 to 100 percent |
| `turnAngleDegrees` | 30.0 | finite, greater than 0 to 45 degrees |
| `startupDelayMs` | 800 | 0 to 10000 milliseconds |
| `promptDelayMs` | 100 | 0 to 1000 milliseconds |
| `movementDelayMs` | 500 | 1 to 10000 milliseconds |
| `loopDelayMs` | 50 | 1 to 1000 milliseconds |
| `finalDelayMs` | 200 | 0 to 1000 milliseconds |

All vision callbacks (`start`, `stop`, `setColor`, `observe`, `delay`, `continueOperation`) and `selectColor`
are required.

## 7. Testing

Host coverage is provided by the vision group test `xWalkDriverVisionGroupHostTest` (labels `host` and
`agent-group`), which checks `colorName()` and the default configuration. From the repository root:

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
- `xWalkComputerVision` for color detection callbacks and types;
- `xWalkGPT` for `hal::XWalkTextToSpeech`;
- `xWalkLibrary/common` for `hal::XWalkOperationCancelled` and shared types;
- `xWalkTrace` for trace and error reporting.

## 9. Safety and constraints

- Movement keys drive the physical car at the configured requested power; each move is bounded by
  `movementDelayMs` and always ends with `stop()`.
- Cancellation is polled at least every 20 milliseconds; a cancelled step stops the motors.
- The Agent does not own or release its injected services.

## 10. Related notes

- [xWalkVision](../xWalkVision.md)
- [xWalkComputerVision](../xWalkComputerVision/xWalkComputerVision.md)
- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md)
- [xWalkGPT](../../../xWalkHal/layer1/xWalkGPT/xWalkGPT.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)

---

[Previous page](../xWalkRoadUserSafety/xWalkRoadUserSafety.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkVideoCar/xWalkVideoCar.md)
