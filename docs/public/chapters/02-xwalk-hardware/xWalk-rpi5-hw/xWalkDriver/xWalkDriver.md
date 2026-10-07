<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [2. xWalk hardware](../../index.md) / xWalkDriver

**2. xWalk hardware &middot; Module 07**

<!-- xwalk-page-header:end -->

# xWalkDriver

`xWalkDriver` is the xWalk Agent layer: a set of C++17 application-level coordinators that port the PiCar-X
example behaviors onto caller-owned xWalk HAL objects. The aggregate interface target `xWalk::Agent` links six
functional groups, each of which is independently buildable and testable.

## 1. Overview

Every Agent module composes HAL objects that the application creates, owns, and destroys. The Agents own no
Linux device node, process entry point, or composition service; timing, cancellation, terminal input, and
provider services are injected through callbacks or caller-owned objects.

Agent production code qualifies the generic shared type vocabulary through the `agent` namespace exported by
`xHal_Rpi5CarTypes.h`. Hardware-specific classes, callbacks, and sensor structures remain explicitly qualified
through `hal`.

The modules keep their existing target names and public headers. Their source directories are physically
organized under six functional parents. Physical grouping does not combine the distinct lifecycles of similarly
named modules. The tree contains 31 child modules: seven Vehicle, three Calibration, nine Vision, one Media,
nine Voice, and two Connectivity modules.

Most modules port one upstream SunFounder PiCar-X example:

| Module | Upstream source |
| --- | --- |
| `xWalkMoveExample` | `example/2.move.py` |
| `xWalkKeyboardControl` | `example/3.keyboard_control.py` |
| `xWalkObstacleAvoidance` | `example/4.avoiding_obstacles.py` |
| `xWalkCliffDetection` | `example/5.cliff_detection.py` |
| `xWalkLineTracking` | `example/6.line_tracking.py` |
| `xWalkComputerVision` | `example/7.computer_vision.py` |
| `xWalkFaceTracking` | `example/8.stare_at_you.py` |
| `xWalkVideoRecording` | `example/9.record_video.py` |
| `xWalkBullFight` | `example/10.bull_fight.py` |
| `xWalkVideoCar` | `example/11.video_car.py` |
| `xWalkAppControl` | `example/12.app_control.py` |
| `xWalkSoundBackgroundMusic` | `example/13.sound_background_music.py` |
| `xWalkVoicePromptCar` | `example/14.voice_promt_car.py` |
| `xWalkStorytellingRobot` | `example/15.storytelling_robot.py` |
| `xWalkVoiceControlledCar` | `example/16.voice_controlled_car.py` |
| `xWalkTextVisionTalk` | `example/17.text_vision_talk.py` |
| `xWalkOnlineLlmTest` | `example/18.online_llm_test.py` |
| `xWalkLocalVoiceChatbot` | `example/19.local_voice_chatbot.py` |
| `xWalkTreasureHunt` | `example/20.treasure_hunt.py` |
| `xWalkVoiceActiveCarGpt` | `example/21.voice_active_car_gpt.py` |
| `xWalkVoiceActiveCar` | `example/voice_active_car.py` |
| `xWalkServoZeroing` | `example/servo_zeroing.py` |
| `xWalkGrayscaleCalibration` | `example/1.cali_grayscale.py` |
| `xWalkServoMotorCalibration` | `example/1.cali_servo_motor.py` |
| `xWalkGptCar` | `gpt_examples/gpt_car.py` |

The remaining modules are project-specific: `xWalkPicarx` is the shared PiCar-X coordinator,
`xWalkSelfDrive` provides named preset actions, `xWalkCameraCapture` adapts the camera HAL to voice image
input, `xWalkRoadUserSafety` is a fail-safe road-user risk boundary, `xWalkVideoStreaming` provides bounded
MJPEG streaming, and `xWalkSpiTransfer` coordinates bounded full-duplex SPI requests.

The command-line runtime is a separate sibling aggregate under `xWalkController`. The standalone Agent tree
does not contain or compose `xWalkController`.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver` (source directory)

## 3. Directory layout

```text
xWalkDriver/
    CMakeLists.txt                  Aggregate options, xWalk::Agent target, and root GoogleTest registration
    test/
        include/                    xAgent_Rpi5CarGroupTestSupport.h child-executable path helpers
        src/                        xWalkDriverGoogleTest host aggregate (one case per group)
        hardware/src/               xWalkDriverHardwareGoogleTest hardware-profile aggregate
    xWalkVehicle/                   Movement, line following, reactions, and preset actions
    xWalkCalibration/               Grayscale, servo, and motor calibration
    xWalkVision/                    Camera capture, detection, tracking, games, video, and streaming
    xWalkMedia/                     Sound effects and background music
    xWalkVoice/                     Speech, narration, voice control, and conversational AI
    xWalkConnectivity/              Mobile-app control and SPI transactions
```

## 4. Child modules

- [xWalkVehicle](xWalkVehicle/xWalkVehicle.md) (`xWalk::AgentVehicle`): movement, line following, preset actions.
- [xWalkCalibration](xWalkCalibration/xWalkCalibration.md) (`xWalk::AgentCalibration`):
  sensor and actuator calibration.
- [xWalkVision](xWalkVision/xWalkVision.md) (`xWalk::AgentVision`): camera, detection, tracking, video.
- [xWalkMedia](xWalkMedia/xWalkMedia.md) (`xWalk::AgentMedia`): sound effects and background music.
- [xWalkVoice](xWalkVoice/xWalkVoice.md) (`xWalk::AgentVoice`): speech, voice control, conversational AI.
- [xWalkConnectivity](xWalkConnectivity/xWalkConnectivity.md) (`xWalk::AgentConnectivity`): app control, SPI.

## 5. Public interface

| Target | Kind | Content |
| --- | --- | --- |
| `xWalkDriver` / `xWalk::Agent` | `INTERFACE` | `xWalkLibraryCommon` plus all six group interface targets |
| `xWalkDriver<Group>` / `xWalk::Agent<Group>` | `INTERFACE` | The child module libraries of one group |

Each child module exports its own static library and `xWalk::<Module>` alias with public headers under its
`include` directory. Consumers that do not need the complete aggregate link one group target or one module.

## 6. Build

The aggregate exposes two mutually exclusive verification modes. Configuring both in one build directory fails.

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_AGENT_BUILD_HOST` | `OFF` | Builds every Agent module, the Robot HAT simulation, and host tests |
| `XWALK_AGENT_BUILD_RPI` | `OFF` | Builds every Agent module, Linux backends, and hardware-labelled executables |

Either mode includes `xWalkLibrary/XWalkDependencies.cmake`, requires GoogleTest, and forces the per-module
and per-group `*_BUILD_HOST_TESTS` or `*_BUILD_HARDWARE_TESTS` cache values. The OpenCV computer-vision and
video-recording providers are built in either mode or when `XWALK_BUILD_ALL_BACKENDS` is set. The RPi mode, or
`XWALK_BUILD_ALL_BACKENDS`, also enables the app-control WebSocket, Linux camera, and Linux SPI backends; the
RPi mode additionally enables the ALSA music, sndfile decoder, speech, Vosk, Espeak, Piper, Pico2Wave, and
Ollama providers. The workspace root sets `XWALK_AGENT_BUILD_HOST` and `XWALK_AGENT_BUILD_RPI` itself.

Standalone host build from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver -B xWalk-rpi5-hw/xWalkDriver/build-host -DXWALK_AGENT_BUILD_HOST=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/build-host --parallel
```

The RPi build compiles Linux backends and hardware-labelled tests without running them:

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver -B xWalk-rpi5-hw/xWalkDriver/build-rpi -DXWALK_AGENT_BUILD_RPI=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/build-rpi --parallel
```

## 7. Configuration

`xWalkPicarx` reads its persisted calibration from the file selected by the `XWALK_PICARX_CONFIG_FILE` cache
value, which defaults to
`xWalkController/xWalkConfig/picar-x.conf`.
Resource directories for sounds and music are supplied by the composing application.

### Runtime tracing

Agent diagnostics use registered `RPIAGENT` trace identifiers. Use an individual selector such as
`--trace RPIAGENT.012.enable` when only one event is needed. Selection is persisted in
`<build-directory>/generated/xwalk-traces.xml`, and records are appended to
`<build-directory>/log/xWalkTrace.log`.

| Functional group | Child module | Trace identifiers |
| --- | --- | --- |
| Calibration | GrayscaleCalibration | `RPIAGENT.022` |
| Calibration | ServoMotorCalibration | `RPIAGENT.023` |
| Calibration | ServoZeroing | `RPIAGENT.016` |
| Connectivity | AppControl | `RPIAGENT.024` |
| Connectivity | SpiTransfer | `RPIAGENT.017` |
| Media | SoundBackgroundMusic | `RPIAGENT.018` |
| Vehicle | CliffDetection | `RPIAGENT.025` |
| Vehicle | KeyboardControl | `RPIAGENT.026` |
| Vehicle | LineTracking | `RPIAGENT.027` |
| Vehicle | MoveExample | `RPIAGENT.028` |
| Vehicle | ObstacleAvoidance | `RPIAGENT.029` |
| Vehicle | Picarx | `RPIAGENT.001` |
| Vehicle | SelfDrive | `RPIAGENT.002`–`RPIAGENT.009` |
| Vision | BullFight | `RPIAGENT.030` |
| Vision | CameraCapture | `RPIAGENT.020` |
| Vision | ComputerVision | `RPIAGENT.021` |
| Vision | FaceTracking | `RPIAGENT.031` |
| Vision | RoadUserSafety | `RPIAGENT.032` |
| Vision | TreasureHunt | `RPIAGENT.033` |
| Vision | VideoCar | `RPIAGENT.034` |
| Vision | VideoRecording | `RPIAGENT.035` |
| Vision | VideoStreaming | `RPIAGENT.036` |
| Voice | GptCar | `RPIAGENT.037` |
| Voice | LocalVoiceChatbot | `RPIAGENT.038` |
| Voice | OnlineLlmTest | `RPIAGENT.039` |
| Voice | StorytellingRobot | `RPIAGENT.040` |
| Voice | TextVisionTalk | `RPIAGENT.041` |
| Voice | VoiceActiveCar | `RPIAGENT.010`–`RPIAGENT.015` |
| Voice | VoiceActiveCarGpt | `RPIAGENT.042` |
| Voice | VoiceControlledCar | `RPIAGENT.043` |
| Voice | VoicePromptCar | `RPIAGENT.044` |

The production-source coverage continues with file-level operational events:

| Trace identifiers | Production source coverage |
| --- | --- |
| `RPIAGENT.045` | Grayscale calibration execution |
| `RPIAGENT.046`–`RPIAGENT.047` | App-control WebSocket facade and worker state |
| `RPIAGENT.076`–`RPIAGENT.083` | Vehicle danger, recovery, input, guard, sensing, and gesture events |
| `RPIAGENT.084` | MJPEG HTTP transport startup |
| `RPIAGENT.085`–`RPIAGENT.086` | Voice response filtering and default-profile selection |
| `RPIAGENT.088`–`RPIAGENT.090` | Voice-active-car continuous conversation start, safe end, and idle timeout |

Every project-owned production `.cpp` below the six Agent functional groups contains at least one registered
diagnostic. Test sources remain governed by their owning test assertions and do not emit production trace IDs.
Warnings remain visible independently of normal trace selection. Agent traces never contain recognized speech,
prompts, model-response text, spoken text, credentials, action text, audio, images, or cleanup callback data.

## 8. Testing

Host verification is deterministic and uses in-memory callbacks and the Robot HAT simulation.

The `xWalkDriverGoogleTest` executable is the root Agent verification layer (labels `host`, `agent`,
`agent-aggregate`; run serially). It contains one GoogleTest case per functional group and runs each group
suite in an isolated process. Each group suite contains at least one case per child module; cases run an
existing deterministic child test in an isolated process where one exists, and newer modules are checked
directly through their public behavior and configuration contracts. Group suites carry the `agent-group`
label.

Run the complete standalone host suite:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-host --output-on-failure
```

Run only the group inventory:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-host --output-on-failure -L agent-group
```

In the workspace `host-debug` build, run only the root aggregate:

```bash
ctest --test-dir build-host/cmake --output-on-failure -L agent-aggregate
```

The Raspberry Pi aggregate registers GoogleTest hardware-profile group suites. Their cases verify the RPi group
build graph; owning child hardware tests retain responsibility for physical device behavior. The
`xWalkDriverHardwareGoogleTest` executable composes the six hardware-profile group suites. Discover the
hardware tests without executing them:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-rpi -N -L hardware
```

Hardware tests are opt-in. Do not run them without explicit approval and a confirmed safe Raspberry Pi and
Robot HAT setup.

## 9. Dependencies

- [xWalkLibrary Common](../xWalkLibrary/common/xWalkLibrary%20Common.md) shared types and errors.
- [xWalkHal](../xWalkHal/xWalkHal.md) device, sensor, interface, and layer-1 modules.
- [xWalkRobotHat](../xWalkHal/simulation/xWalkRobotHat/xWalkRobotHat.md) simulation for host builds.
- [xWalk-rpi5-trace](../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) registered trace macros.
- GoogleTest; OpenCV, Boost, json-c, ALSA, and speech providers for optional backends.

## 10. Safety and constraints

Never execute the RPi tests until the correct Raspberry Pi and Robot HAT are connected, wheels are lifted, the
camera and steering mechanisms have clear travel, and powered motion has been approved. Agents that move
motors or servos rely on caller-provided cancellation and on the `xWalkPicarx` emergency-stop path.

## 11. Related notes

- [xWalk-rpi5-hw](../xWalk-rpi5-hw.md)
- [xWalkController](../xWalkController/xWalkController.md)
- [xWalkAudioResources](../xWalkAudioResources/xWalkAudioResources.md)

---

[Previous page](../xWalkController/xWalkStandAlone/xWalkStandAlone.md) · [Chapter index](../../index.md) · [Next page](xWalkCalibration/xWalkCalibration.md)
