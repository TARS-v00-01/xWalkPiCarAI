<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkVision

**2. xWalk hardware &middot; Module 25**

<!-- xwalk-page-header:end -->

# xWalkVision

`xWalkVision` is the Vision functional group of the xWalk Agent layer. It groups camera capture, detection,
tracking, games, video, road-user safety, and MJPEG streaming coordinators behind the `xWalk::AgentVision`
interface target.

## 1. Overview

The group contains `xWalkComputerVision`, `xWalkFaceTracking`, `xWalkBullFight`, `xWalkTreasureHunt`,
`xWalkVideoRecording`, `xWalkVideoCar`, `xWalkCameraCapture`, `xWalkRoadUserSafety`, and the bounded
`xWalkVideoStreaming` MJPEG core. Portable coordinators remain separate from optional OpenCV and
physical-camera providers.

`xWalkRoadUserSafety` provides validated detector and classifier interfaces plus fail-safe motion-stop
behavior. Its deterministic scenarios do not constitute a trained YOLO or Random Forest implementation;
production models and physical stop verification remain separate deployment work.

`xWalkVideoStreaming` validates and queues JPEG frames for multiple logical clients with bounded memory and
drop-oldest backpressure. It also contains a bounded non-blocking MJPEG HTTP transport that defaults to a
loopback bind address and requires an authentication reference and callback for any non-loopback address.
Physical camera delivery and deployment exposure remain integration work.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision`
(source directory)

## 3. Directory layout

```text
xWalkVision/
    CMakeLists.txt                  Group options, xWalk::AgentVision target, and group test registration
    test/
        include/                    xAgent_Rpi5CarVisionTestSupport.h deterministic vision callback state
        src/                        xWalkDriverVisionGroupTest host suite and test support
        hardware/src/               xWalkDriverVisionGroupHardwareTest hardware-profile suite
        assets/                     Recorded-scenario fixtures, manifests, and validation scripts
    xWalkComputerVision/            Interactive detection state machine and optional OpenCV provider
    xWalkFaceTracking/              Camera-servo face tracking
    xWalkBullFight/                 Red-target tracking and pursuit
    xWalkTreasureHunt/              Random color-target game
    xWalkVideoRecording/            Callback-driven recording and optional OpenCV AVI provider
    xWalkVideoCar/                  Interactive driving with photo capture
    xWalkCameraCapture/             Camera HAL adapter for voice image input
    xWalkRoadUserSafety/            Fail-safe road-user risk boundary
    xWalkVideoStreaming/            Bounded MJPEG stream core and HTTP transport
```

## 4. Child modules

| Note | Responsibility |
| --- | --- |
| [xWalkComputerVision](xWalkComputerVision/xWalkComputerVision.md) | `example/7.computer_vision.py` |
| [xWalkFaceTracking](xWalkFaceTracking/xWalkFaceTracking.md) | `example/8.stare_at_you.py` camera-servo tracking |
| [xWalkBullFight](xWalkBullFight/xWalkBullFight.md) | `example/10.bull_fight.py` red-target pursuit |
| [xWalkTreasureHunt](xWalkTreasureHunt/xWalkTreasureHunt.md) | `example/20.treasure_hunt.py` color-target game |
| [xWalkVideoRecording](xWalkVideoRecording/xWalkVideoRecording.md) | `example/9.record_video.py` AVI recording |
| [xWalkVideoCar](xWalkVideoCar/xWalkVideoCar.md) | `example/11.video_car.py` driving and photos |
| [xWalkCameraCapture](xWalkCameraCapture/xWalkCameraCapture.md) | JPEG capture for voice image input |
| [xWalkRoadUserSafety](xWalkRoadUserSafety/xWalkRoadUserSafety.md) | Road-user risk and fail-safe stop |
| [xWalkVideoStreaming](xWalkVideoStreaming/xWalkVideoStreaming.md) | Bounded MJPEG streaming |
| [xWalkVision Test Assets](test/assets/xWalkVision%20Test%20Assets.md) | Recorded-scenario test fixtures |

## 5. Public interface

`xWalkDriverVision` (alias `xWalk::AgentVision`) is a C++17 `INTERFACE` target that links all nine child module
libraries. Optional OpenCV providers are separate targets that consumers link explicitly.

## 6. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_AGENT_VISION_BUILD_HOST_TESTS` | `OFF` | Builds the group host suite and forces child host tests on |
| `XWALK_AGENT_VISION_BUILD_HARDWARE_TESTS` | `OFF` | Builds the hardware-profile group suite |

The host option forces the computer-vision, video-recording, camera-capture, camera HAL, road-user-safety, and
video-streaming host tests on. Either option includes `xWalkLibrary/XWalkDependencies.cmake` and requires
GoogleTest.

## 7. Testing

`xWalkDriverVisionGroupHostTest` (labels `host`, `agent-group`) contains 15 cases. Modules with a standalone
test run it in an isolated process. `FaceTracking`, `BullFight`, `TreasureHunt`, and `VideoCar` are checked
directly through their public behavior and configuration contracts; their lifecycle, cancellation, and
validation cases use the shared vision test support, the PiCar-X test support, and the Robot HAT simulation.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-host --output-on-failure -R xWalkDriverVisionGroupHostTest
```

`xWalkDriverVisionGroupHardwareTest` (labels `hardware`, `agent-group`) checks the RPi build graph for seven
modules; `RoadUserSafety` and `VideoStreaming` have no hardware-profile case. Discover hardware tests with
`ctest -N -L hardware`; do not run them without explicit approval, camera-placement and privacy consent, and a
confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- [xWalkPicarx](../xWalkVehicle/xWalkPicarx/xWalkPicarx.md) for motion-capable vision Agents.
- [xWalkCamera](../../xWalkHal/device/xWalkCamera/xWalkCamera.md) camera HAL.
- [xWalkRobotHat](../../xWalkHal/simulation/xWalkRobotHat/xWalkRobotHat.md) for the group host suite.
- OpenCV for optional providers and recorded-media tests; Python 3 for fixture validation.

## 9. Safety and constraints

Camera capture can record people and private surroundings. Use it only with authorization and protect saved
images according to local policy.

Every Vision child module owns a registered `RPIAGENT` lifecycle or bounded-operation trace. Use the
authoritative [Agent trace table](../xWalkDriver.md#runtime-tracing) to select one child. Traces exclude
images, frames, detected text, network payloads, and resource paths.

## 10. Related notes

- [xWalkDriver](../xWalkDriver.md)
- [xWalkVoice](../xWalkVoice/xWalkVoice.md)

---

[Previous page](../xWalkVehicle/xWalkSelfDrive/xWalkSelfDrive.md) · [Chapter index](../../../index.md) · [Next page](xWalkBullFight/xWalkBullFight.md)
