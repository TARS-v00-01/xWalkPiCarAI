<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkHal Layer1

**2. xWalk hardware &middot; Module 87**

<!-- xwalk-page-header:end -->

# xWalkHal Layer1

The Layer 1 group contains the higher-level robot services and features of the xWalk HAL. Its modules compose
the interface, device, and sensor groups into board services, multi-servo coordination, music and speaker
playback, speech input and output, and the voice-assistant workflow.

## 1. Overview

Layer 1 is the top HAL group. Dependencies flow from `interface` through `device` and `sensor` to `layer1`.
Each Layer 1 module builds one static library, exports headers from its own `include` directory, and keeps
platform backends in a separate `hardware` directory or in lower-group Linux libraries. Every module
contains a device-free standalone simulation and host tests.

The `test` directory adds a group interaction suite that checks how the Layer 1 modules work together.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1` (source directory)

## 3. Directory layout

```text
layer1/
├── test/                   Layer 1 group interaction suite (xWalkLayer1GroupTest)
├── xWalkBoardControl/      Robot HAT board services, device discovery, and firmware version
├── xWalkGPT/               Speech-to-text and text-to-speech coordinators and providers
├── xWalkMusic/             Tone, note, and music-file playback
├── xWalkRobot/             Articulated multi-servo coordinator
├── xWalkSpeaker/           Asynchronous audio-file playback tasks
└── xWalkVoiceAssistant/    Synchronous speech, model, and speech-output orchestration
```

## 4. Child modules

| Note | Description |
|---|---|
| [xWalkHal Layer1 Tests](test/xWalkHal%20Layer1%20Tests.md) | Group interaction suite for the Layer 1 modules |
| [xWalkBoardControl](xWalkBoardControl/xWalkBoardControl.md) | Board control, discovery, and firmware info |
| [xWalkGPT](xWalkGPT/xWalkGPT.md) | Speech recognition and synthesis coordination |
| [xWalkMusic](xWalkMusic/xWalkMusic.md) | Music and tone generation |
| [xWalkRobot](xWalkRobot/xWalkRobot.md) | Bounded multi-servo robot coordination |
| [xWalkSpeaker](xWalkSpeaker/xWalkSpeaker.md) | Speaker playback tasks |
| [xWalkVoiceAssistant](xWalkVoiceAssistant/xWalkVoiceAssistant.md) | Listen, model, and speak orchestration |

## 5. Build

The group has no aggregate CMake file. The workspace project in `xWalk-rpi5-hw` adds the modules in this order:
`xWalkMusic`, `xWalkSpeaker`, `xWalkBoardControl`, `xWalkRobot`, `xWalkGPT`, and `xWalkVoiceAssistant`. It adds
the `test` directory only in the HAL host mode. Each module can also be configured standalone from its own
directory; see the module notes.

## 6. Testing

The group interaction suite builds `xWalkLayer1GroupTest` and registers it with the CTest labels
`host;layer1-group;group-tests`. From the `xWalk-rpi5-hw` directory:

```bash
cmake -S . -B build-host/group-tests -DBUILD_TESTING=ON -DXWALK_BUILD_RPI=OFF -DCMAKE_BUILD_TYPE=Debug
cmake --build build-host/group-tests --target xWalkLayer1GroupTest --parallel
build-host/group-tests/xWalkHal/layer1/test/xWalkLayer1GroupTest
ctest --test-dir build-host/group-tests -L layer1-group --output-on-failure
```

Module host tests are collected by the central `xGoogleTest` executable in a workspace build. Hardware-labelled
module tests are opt-in; list them in a Raspberry Pi build with `ctest -N -L hardware`.

## 7. Dependencies

- Interface group: `xWalkAudio`, `xWalkConfig`, `xWalkGpio`, `xWalkI2c`, and `xWalkLanguageModel`.
- Device group: `xWalkAdc`, `xWalkPwm`, and `xWalkServo`.
- `xWalkLibraryCommon` and `xWalkTrace`.
- Within the group, `xWalkGPT` links `xWalkBoardControl`, and `xWalkVoiceAssistant` links `xWalkGPT` and
  `xWalkLanguageModel`.
- Raspberry Pi backends use ALSA, libsndfile, Vosk, Piper, Espeak, and Pico2Wave as selected by the workspace.

## 8. Safety and constraints

- Host tests and simulations use deterministic callbacks and never open audio, GPIO, I2C, microphone, model,
  or network resources.
- Layer 1 modules store non-owning references; every injected dependency must outlive its consumer.
- Hardware tests can produce audible output, drive Robot HAT outputs, or capture microphone audio. Run them only
  with explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 9. Related notes

- [xWalkHal](../xWalkHal.md)
- [xWalkHal Interface Layer](../interface/xWalkHal%20Interface%20Layer.md)
- [xWalkHal Device Layer](../device/xWalkHal%20Device%20Layer.md)
- [xWalkHal Sensor Layer](../sensor/xWalkHal%20Sensor%20Layer.md)
- [xGoogleTest](../xWalkTest/xGoogleTest/xGoogleTest.md)

---

[Previous page](../interface/xWalkWebSearch/xWalkWebSearch.md) · [Chapter index](../../../index.md) · [Next page](xWalkBoardControl/xWalkBoardControl.md)
