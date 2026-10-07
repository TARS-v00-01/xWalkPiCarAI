<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkAppControl

**2. xWalk hardware &middot; Module 13**

<!-- xwalk-page-header:end -->

# xWalkAppControl

`xWalkAppControl` ports upstream `example/12.app_control.py` into a bounded, provider-neutral foreground
coordinator. It publishes speed, grayscale, and distance telemetry and consumes the SunFounder A-Q control
state through an injected transport.

## 1. Overview

The coordinator preserves joystick driving, camera pan/tilt, voice movement, line tracking, obstacle
avoidance, horn requests, and red/face detection. Each `step()` publishes telemetry, polls one input snapshot,
and applies at most one motion mode in this priority: line tracking, obstacle avoidance, then the drive
joystick. A spoken command is applied before the motion mode.

- Voice commands `forward`, `backward`, and `stop` use the current speed; `left` and `right` (and the
  upstream-recognized `white` and `rice` variants, which turn right) steer ±30 degrees at 60 percent for
  1.2 seconds.
- The drive joystick maps X to steering at 0.3 degrees per unit and Y to signed speed, both clamped to ±100.
- Camera joystick angles are clamped to -90 through 90 degrees pan and -35 through 65 degrees tilt.
- Obstacle avoidance drives forward at or above 40 centimeters, turns right for 100 milliseconds from
  20 centimeters, and reverses left for 500 milliseconds below 20 centimeters. A distance at or below zero
  stops the vehicle.
- Line recovery is bounded by `maximumLineRecoverySamples`.
- Color detection toggles red detection; face detection toggles through the computer-vision callbacks.

TensorFlow object detection is reported as unavailable (`ObjectDetectionUnsupported`) because the current
OpenCV provider does not expose the upstream TFLite model.

Network binding belongs to the application-owned provider and must be explicitly configured. The Agent itself
never opens a listener or starts Vilib's web server.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkConnectivity/xWalkAppControl`
(source directory)

## 3. Directory layout

```text
xWalkAppControl/
    CMakeLists.txt                                   Core library and optional WebSocket provider
    include/
        xAgent_Rpi5CarAppControl.h                   Public coordinator contract
        xAgent_Rpi5CarAppControlTypes.h              Input, telemetry, event, result, callback, configuration
    src/
        xAgent_Rpi5CarAppControl.cpp                 Voice, line, obstacle, joystick, and detection handling
        xAgent_Rpi5CarAppControlLifecycle.cpp        Validation, start, finish, and cancellable waits
    hardware/
        include/xAgent_Rpi5CarAppControlWebSocket.h  WebSocket provider facade
        include/xAgent_Rpi5CarAppControlWebSocketState.h  Provider worker state
        src/                                         Boost.Asio and json-c provider implementation
    test/
        include/xAgent_Rpi5CarAppControlTestSupport.h  Reusable fake transport declarations
        src/xAgent_Rpi5CarAppControlTestSupport.cpp    Fake transport implementation
```

## 4. Public interface

`xwalk::agent::XWalkAppControl` (non-copyable, non-movable) is constructed from an `XWalkPicarx&`, an
`XWalkAppControlCallbacks` table, and an optional `XWalkAppControlConfiguration`.

| Member | Behavior |
| --- | --- |
| `start()` | Starts the transport and vision providers |
| `step()` | Publishes telemetry, polls input, and applies one bounded control step |
| `finish()` | Stops motion and providers |
| `started()` | Reports the started state |

`step()` before `start()` is a logic error. `XWalkAppControlResult` carries an `XWalkAppControlEvent`
(`Idle`, `JoystickMotion`, `VoiceMotion`, `LineTracking`, `ObstacleAvoidance`, `HornRequested`,
`ObjectDetectionUnsupported`, `Cancelled`), the published telemetry, and horn and object-detection flags.
Cancellation through the vision continuation callback stops the motors.

The optional `xwalk::agent::XWalkAppControlWebSocket` provider is constructed with an explicit bind address
and returns a complete callback table through `callbacks(visionCallbacks)`.

## 5. Configuration

| Field | Default | Valid range |
| --- | --- | --- |
| `controllerName` | `Picarx-001` | Non-empty |
| `controllerType` | `Picarx` | Non-empty |
| `videoUrl` | empty | Published unchanged |
| `controllerPort` | 8765 | Non-zero |
| `lineTrackingSpeedPercent` | 10.0 | Finite, 0 through 100 |
| `lineTrackingAngleDegrees` | 20.0 | Finite, 0 through 30 |
| `obstacleSpeedPercent` | 40.0 | Finite, 0 through 100 |
| `maximumLineRecoverySamples` | 1,000 | 1 through 100,000 |
| `sampleDelayMs` | 10 | 1 through 1,000 milliseconds |

Every transport callback and the vision `start`, `stop`, `setColor`, `setFace`, `delay`, and
`continueOperation` callbacks are required.

## 6. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_APP_CONTROL_BUILD_WEBSOCKET_BACKEND` | `OFF` | Builds `xWalk::AppControlWebSocket` |

The core builds `xWalkAppControl` (alias `xWalk::AppControl`) and adds `xWalkPicarx` and `xWalkComputerVision`
with their tests and OpenCV backend disabled when the targets are not already defined. The WebSocket provider
requires Boost 1.74 or newer, `json-c` through pkg-config, and Threads. The aggregate
[xWalkDriver](../../xWalkDriver.md) RPi mode enables the provider.

## 7. Testing

The module registers no standalone test. The [xWalkConnectivity](../xWalkConnectivity.md) group host suite
exercises the coordinator through the shared fake transport and the Robot HAT simulation, covering lifecycle,
input modes, start failures, and validation.

## 8. Dependencies

- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md) and
  [xWalkComputerVision](../../xWalkVision/xWalkComputerVision/xWalkComputerVision.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).
- Boost, json-c, and Threads for the optional WebSocket provider.

## 9. Safety and constraints

App control drives the motors and camera servos from remote input. Bind the provider only to an explicitly
reviewed address and run physical sessions only on an approved Raspberry Pi and Robot HAT setup with clear
travel.

The coordinator emits `RPIAGENT.024` when providers start; the WebSocket provider emits `RPIAGENT.046` and
`RPIAGENT.047`. See the [Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 10. Related notes

- [xWalkConnectivity](../xWalkConnectivity.md)
- [xWalkLineTracking](../../xWalkVehicle/xWalkLineTracking/xWalkLineTracking.md)
- [xWalkObstacleAvoidance](../../xWalkVehicle/xWalkObstacleAvoidance/xWalkObstacleAvoidance.md)

---

[Previous page](../xWalkConnectivity.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkSpiTransfer/xWalkSpiTransfer.md)
