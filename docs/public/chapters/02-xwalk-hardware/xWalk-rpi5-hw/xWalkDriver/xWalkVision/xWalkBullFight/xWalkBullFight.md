<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkBullFight

**2. xWalk hardware &middot; Module 26**

<!-- xwalk-page-header:end -->

# xWalkBullFight

`xWalkBullFight` ports `example/10.bull_fight.py` through caller-owned PiCar-X and computer-vision services. It
selects red detection, tracks the target with bounded camera angles, steers to the retained pan command, drives
forward at 50 percent, and commands zero power while no target is visible.

## 1. Overview

`XWalkBullFight` is a step-driven Agent coordinator. It owns no camera, detector, servo, or motor. Each `step()`
samples one color observation from the `xWalkComputerVision` callback boundary and applies the result to a
caller-owned `XWalkPicarx`:

- with a visible target, pan and tilt are corrected by the target position inside the configured frame, each
  constrained to the configured maximum camera angle, then the steering servo follows the pan angle and the car
  drives forward at the configured speed;
- without a visible target, the car is commanded to zero forward power and the state is `Searching`;
- cancellation before sampling or during the sample delay stops the vehicle and reports `Cancelled`.

The source's retained one-degree `dir_angle` calculation is preserved for compatibility even though the upstream
steering call uses `x_angle`. The direction value is reported in `XWalkBullFightResult::directionAngleDegrees`,
while the steering servo receives the pan angle.

`start()` resets all angles, starts the provider, and enables red detection. `finish()` stops the vehicle, stops
an active provider, resets the angles, and applies the final delay. The destructor stops an active provider and
requests an emergency stop on the PiCar-X object. Physical camera, servo, and motor execution remains opt-in.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkBullFight`
(source directory)

## 3. Directory layout

```text
xWalkBullFight/
    CMakeLists.txt                              Static library, alias, and dependency wiring
    include/
        xAgent_Rpi5CarBullFight.h               XWalkBullFight coordinator contract
        xAgent_Rpi5CarBullFightTypes.h          State, configuration, and step-result types
    src/
        xAgent_Rpi5CarBullFight.cpp             Tracking step, angle limits, and motor-power setter
        xAgent_Rpi5CarBullFightLifecycle.cpp    Validation, start, finish, cancellable delay, destructor
```

The module has no test directory of its own. Host coverage lives in the vision group test.

## 4. Public interface

Public headers `xAgent_Rpi5CarBullFight.h` and `xAgent_Rpi5CarBullFightTypes.h` are in
`include`.

| Member | Behavior |
| --- | --- |
| `XWalkBullFight(picarx, context, callbacks, configuration)` | Binds dependencies and validates them |
| `start()` | Starts the provider and selects red; returns `true` when already started |
| `step()` | Runs one sample; throws a logic error before a successful `start()` |
| `finish()` | Stops motion and the provider, resets angles, waits `finalDelayMs` |
| `started()` | Reports whether the provider is active |
| `setMotorPowerPercent(percent)` | Replaces the forward speed used by later steps |

`XWalkBullFightState` reports `Searching`, `Pursuing`, or `Cancelled`. `XWalkBullFightResult` carries the state,
the color detection, and the pan, tilt, and direction angles in degrees.

The constructor requires the `start`, `stop`, `setColor`, `observe`, `delay`, and `continueOperation` callbacks.
The PiCar-X reference and callback context are non-owning; both must outlive the coordinator. The class is neither
copyable nor movable.

## 5. Build

The CMake target is `xWalkBullFight` with the alias `xWalk::BullFight`. It is a C++17 static library that links
`xWalkPicarx` and `xWalkComputerVision` publicly and `xWalkTrace` privately. When the dependency targets are not
already defined, the module adds `xWalkPicarx` and `xWalkComputerVision` itself with their tests and the OpenCV
backend disabled. GCC and Clang builds use `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`.

The aggregate `xWalk::AgentVision` interface target links this library.

## 6. Configuration

`XWalkBullFightConfiguration` fields, defaults, and validated ranges:

| Field | Default | Valid range |
| --- | --- | --- |
| `frameWidthPixels` | 640 | 16 through 7680 pixels |
| `frameHeightPixels` | 480 | 16 through 4320 pixels |
| `correctionSpanDegrees` | 10.0 | finite, greater than 0 through 180 degrees |
| `maximumCameraAngleDegrees` | 35.0 | finite, greater than 0 through 90 degrees |
| `speedPercent` | 50.0 | finite, 0 through 100 percent |
| `sampleDelayMs` | 50 | 1 through 1000 milliseconds |
| `finalDelayMs` | 100 | 0 through 1000 milliseconds |

Invalid callbacks or non-finite values throw an invalid-argument error; out-of-range values throw a range error.
Delays run in cancellable slices of at most 20 milliseconds.

### Runtime motor power

`setMotorPowerPercent(percent)` accepts finite values from 0 through 100 and changes subsequent movement commands.
Invalid values throw without changing the prior setting. The owner must serialize the setter with driver steps.
Controller applies GPB updates on its device-owning worker; MQTT threads never mutate driver settings. Zero power
preserves the mode's sensing and decisions while requesting no motor drive. Existing stop, sensor-failure, and
cancellation behavior remains authoritative.

## 7. Testing

`CMakeLists.txt` declares `XWALK_BULL_FIGHT_BUILD_HOST_TESTS`, but the module defines no test target. Host
coverage is provided by the `XWalkAgentVisionGroup.BullFight*` cases in `xAgent_Rpi5CarVisionGroupTest.cpp` under
`xWalkVision/test/src`,
which use a simulated Robot HAT. They verify default configuration, lifecycle, `Pursuing` and `Searching`
transitions, cancellation, and rejection of incomplete callbacks and out-of-range settings. The group test is
registered as `xWalkDriverVisionGroupHostTest` with the labels `host` and `agent-group`.

From a configured workspace host build:

```bash
ctest --test-dir build-host/cmake -R xWalkDriverVisionGroupHostTest --output-on-failure
```

The vision group hardware-profile test only checks type availability. Discover hardware-labelled tests with
`ctest -N -L hardware`; run them only with explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- `xWalkPicarx`: camera pan and tilt, steering servo, forward drive, stop, and emergency stop.
- `xWalkComputerVision`: callback types, color selection, and observations.
- `xWalkTrace`: lifecycle trace `RPIAGENT.030`, emitted when the provider starts with red detection enabled.

## 9. Safety and constraints

- The car drives forward toward a red target. Run physical tests only with a clear area, the wheels free or the
  car supervised, and an immediate stop available.
- Steering follows the camera pan angle, limited by `maximumCameraAngleDegrees`; the PiCar-X object applies its
  own servo limits.
- Cancellation stops the vehicle; destruction requests an emergency stop.
- Calls are synchronous; the owner must serialize `step()`, `finish()`, and `setMotorPowerPercent()`.

## 10. Related notes

- [xWalkVision](../xWalkVision.md)
- [xWalkComputerVision](../xWalkComputerVision/xWalkComputerVision.md)
- [xWalkFaceTracking](../xWalkFaceTracking/xWalkFaceTracking.md)
- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md)
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkVision.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkCameraCapture/xWalkCameraCapture.md)
