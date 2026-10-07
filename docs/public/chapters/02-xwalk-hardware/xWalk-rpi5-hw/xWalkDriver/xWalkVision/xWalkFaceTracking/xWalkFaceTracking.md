<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkFaceTracking

**2. xWalk hardware &middot; Module 29**

<!-- xwalk-page-header:end -->

# xWalkFaceTracking

`xWalkFaceTracking` ports `example/8.stare_at_you.py` behind the Agent boundary. It consumes face coordinates
from `xWalkComputerVision`, updates the caller-owned PiCar-X camera servos, and retains the upstream 640-by-480
correction formula, 35-degree limits, 50-millisecond sample delay, and final 100-millisecond delay.

## 1. Overview

`XWalkFaceTracking` is a step-driven coordinator. The module owns no camera or vehicle hardware. Raspberry Pi
composition is provided by the owning application; deterministic verification uses injected callbacks.

Each `step()` samples one observation. When a face is visible, the horizontal and vertical corrections are computed
from the face center relative to the configured frame and correction span, added to the retained pan and tilt
angles, constrained to plus or minus the maximum angle, and applied to the camera servos. The state is then
`Tracking`; otherwise it remains `Searching`. The module never drives the wheels. Cancellation before sampling or
during the sample delay calls `stop()` on the vehicle and reports `Cancelled`.

`start()` resets both angles, starts the provider, and enables face detection. `finish()` stops the vehicle, stops
an active provider, resets the angles, and applies the final delay. The destructor stops an active provider and
requests an emergency stop on the PiCar-X object.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkFaceTracking`
(source directory)

## 3. Directory layout

```text
xWalkFaceTracking/
    CMakeLists.txt                                 Static library, alias, and dependency wiring
    include/
        xAgent_Rpi5CarFaceTracking.h               XWalkFaceTracking coordinator contract
        xAgent_Rpi5CarFaceTrackingTypes.h          State, configuration, and step-result types
    src/
        xAgent_Rpi5CarFaceTracking.cpp             Tracking step and angle limits
        xAgent_Rpi5CarFaceTrackingLifecycle.cpp    Validation, start, finish, cancellable delay, accessors
```

The module has no test directory of its own. Host coverage lives in the vision group test.

## 4. Public interface

Public headers `xAgent_Rpi5CarFaceTracking.h` and `xAgent_Rpi5CarFaceTrackingTypes.h` are in
`include`.

| Member | Behavior |
| --- | --- |
| `XWalkFaceTracking(picarx, context, callbacks, configuration)` | Binds dependencies and validates them |
| `start()` | Starts the provider and enables face detection; returns `true` when already started |
| `step()` | Runs one sample; throws a logic error before a successful `start()` |
| `finish()` | Stops the vehicle and provider, resets angles, waits `finalDelayMs` |
| `panAngleDegrees()`, `tiltAngleDegrees()` | Return the retained camera angles in degrees |
| `started()` | Reports whether the provider is active |

`XWalkFaceTrackingState` reports `Searching`, `Tracking`, or `Cancelled`. `XWalkFaceTrackingResult` carries the
state, the face detection, and the pan and tilt angles.

The constructor requires the `start`, `stop`, `setFace`, `observe`, `delay`, and `continueOperation` callbacks.
The PiCar-X reference and callback context are non-owning and must outlive the coordinator. The class is neither
copyable nor movable.

## 5. Build

The CMake target is `xWalkFaceTracking` with the alias `xWalk::FaceTracking`. It is a C++17 static library that
links `xWalkPicarx` and `xWalkComputerVision` publicly and `xWalkTrace` privately. When the dependency targets are
not already defined, the module adds them itself with their tests and the OpenCV backend disabled. GCC and Clang
builds use `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`. The aggregate `xWalk::AgentVision` interface
target links this library.

## 6. Configuration

`XWalkFaceTrackingConfiguration` fields, defaults, and validated ranges:

| Field | Default | Valid range |
| --- | --- | --- |
| `frameWidthPixels` | 640 | 16 through 7680 pixels |
| `frameHeightPixels` | 480 | 16 through 4320 pixels |
| `correctionSpanDegrees` | 10.0 | finite, greater than 0 through 180 degrees |
| `maximumAngleDegrees` | 35.0 | finite, greater than 0 through 90 degrees |
| `sampleDelayMs` | 50 | 1 through 1000 milliseconds |
| `finalDelayMs` | 100 | 0 through 1000 milliseconds |

Incomplete callbacks or non-finite angles throw an invalid-argument error; out-of-range values throw a range error.
Delays run in cancellable slices of at most 20 milliseconds.

## 7. Testing

`CMakeLists.txt` declares `XWALK_FACE_TRACKING_BUILD_HOST_TESTS`, but the module defines no test target. Host
coverage is provided by the `XWalkAgentVisionGroup.FaceTracking*` cases in `xAgent_Rpi5CarVisionGroupTest.cpp`
under
`xWalkVision/test/src`,
which use a simulated Robot HAT. They verify default configuration, lifecycle, `Tracking` and `Searching`
transitions, cancellation, and rejection of incomplete callbacks and out-of-range settings. The group test is
registered as `xWalkDriverVisionGroupHostTest` with the labels `host` and `agent-group`.

From a configured workspace host build:

```bash
ctest --test-dir build-host/cmake -R xWalkDriverVisionGroupHostTest --output-on-failure
```

Discover hardware-labelled tests with `ctest -N -L hardware`; run them only with explicit approval and a confirmed
safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- `xWalkPicarx`: camera pan and tilt servos, stop, and emergency stop.
- `xWalkComputerVision`: callback types, face-detector switch, and observations.
- `xWalkTrace`: lifecycle trace `RPIAGENT.031`, emitted when the provider starts.

## 9. Safety and constraints

- Only the camera pan and tilt servos move; angles never exceed `maximumAngleDegrees` in either direction.
- Face tracking processes images of people. Use it only with authorization and according to local privacy policy.
- Calls are synchronous; the owner must serialize `step()` and `finish()`.

## 10. Related notes

- [xWalkVision](../xWalkVision.md)
- [xWalkComputerVision](../xWalkComputerVision/xWalkComputerVision.md)
- [xWalkBullFight](../xWalkBullFight/xWalkBullFight.md)
- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md)
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkComputerVision/xWalkComputerVision.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkRoadUserSafety/xWalkRoadUserSafety.md)
