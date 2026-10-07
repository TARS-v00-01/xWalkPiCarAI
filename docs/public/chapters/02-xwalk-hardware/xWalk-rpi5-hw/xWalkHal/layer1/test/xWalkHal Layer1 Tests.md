<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkHal Layer1 Tests

**2. xWalk hardware &middot; Module 92**

<!-- xwalk-page-header:end -->

# xWalkHal Layer1 Tests

The Layer 1 group interaction suite builds the `xWalkLayer1GroupTest` GoogleTest executable. It complements the
individual module tests by checking how Board Control, Robot, Music, Speaker, GPT, and Voice Assistant work
together through deterministic, device-free callbacks.

## 1. Overview

The suite checks board readiness and configured Robot initialization, silent Music-to-Speaker flow, and the
complete speech-to-model-to-speech Voice Assistant workflow. It also verifies that critical failures prevent
later output and that stopping the assistant returns it to a non-running state.

Audio decoding, ALSA, speech recognition, speech synthesis, language models, I2C, and GPIO use deterministic
callbacks. A condition-variable handshake with a bounded wait lets the fake speaker confirm worker output without
timing sleeps or real playback.

The suite contains four `XWalkLayer1Group` cases:

- `BoardControlAndRobotInitializationUseInjectedDependencies` verifies MCU reset, battery reading, persisted
  servo offsets, ordered Robot initialization and reset, and rejection of a robot without servos.
- `MusicAndSpeakerWorkflowRemainsSilentAndDeviceFree` verifies 440 Hz tone generation at 44.1 kHz mono, speaker
  decode, open, write, and close, and rejection of invalid audio and negative durations.
- `VoiceAssistantRunsOrderedSpeechModelAndOutputFlow` verifies speaker preparation, the welcome output, the
  listen timeout, the prompt text and image path, the spoken response, and stop.
- `VoiceAssistantStopsDataFlowAfterCriticalFailures` verifies that silence, recognition failure, model failure,
  and output failure suppress the later stages.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/test` (source directory)

## 3. Directory layout

```text
test/
├── CMakeLists.txt                                  Builds and registers xWalkLayer1GroupTest
├── include/
│   └── xHal_Rpi5CarLayer1GroupTestSupport.h        VoicePipelineFixture in xwalk::hal::test::layer1
└── src/
    ├── xHal_Rpi5CarLayer1GroupTest.cpp             Group scenarios
    └── xHal_Rpi5CarLayer1GroupTestSupport.cpp      Fixture implementation
```

The executable also compiles the reusable test-support sources of `xWalkMusic`, `xWalkSpeaker`,
`xWalkBoardControl`, `xWalkRobot`, `xWalkGPT`, `xWalkVoiceAssistant`, and the interface-group
`xWalkLanguageModel`, listed explicitly in
`CMakeLists.txt`.

## 4. Build

The workspace adds this directory only in the HAL host mode (`BUILD_TESTING=ON` and `XWALK_BUILD_RPI=OFF`).
From the `xWalk-rpi5-hw` directory:

```bash
cmake -S . -B build-host/group-tests -DBUILD_TESTING=ON -DXWALK_BUILD_RPI=OFF -DCMAKE_BUILD_TYPE=Debug
cmake --build build-host/group-tests --target xWalkLayer1GroupTest --parallel
```

The target compiles with `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion` on GCC and Clang. Test files
are written below `test-data` in the build directory through `XWALK_LAYER1_GROUP_TEST_DATA_DIRECTORY`.

## 5. Testing

The CTest entry `xWalkLayer1GroupTest` carries the labels `host;layer1-group;group-tests`:

```bash
build-host/group-tests/xWalkHal/layer1/test/xWalkLayer1GroupTest
ctest --test-dir build-host/group-tests -L layer1-group --output-on-failure
```

The suite has no hardware-labelled tests.

## 6. Dependencies

- GoogleTest (`GTest::gtest_main`) and the GoogleMock library and headers.
- `xWalkBoardControl`, `xWalkGPT`, `xWalkLanguageModel`, `xWalkMusic`, `xWalkRobot`, `xWalkSpeaker`,
  `xWalkVoiceAssistant`, and `xWalkTrace`.

## 7. Safety and constraints

The suite opens no GPIO, I2C, ALSA, microphone, model, or network resource and produces no audible output.
Reusable fixtures stay in the named `xwalk::hal::test::layer1` namespace and the owning modules' support
namespaces, following the repository-wide test-support layout.

## 8. Related notes

- [xWalkHal Layer1](../xWalkHal%20Layer1.md)
- [xWalkBoardControl](../xWalkBoardControl/xWalkBoardControl.md)
- [xWalkRobot](../xWalkRobot/xWalkRobot.md)
- [xWalkMusic](../xWalkMusic/xWalkMusic.md)
- [xWalkSpeaker](../xWalkSpeaker/xWalkSpeaker.md)
- [xWalkGPT](../xWalkGPT/xWalkGPT.md)
- [xWalkVoiceAssistant](../xWalkVoiceAssistant/xWalkVoiceAssistant.md)
- [xWalkHal](../../xWalkHal.md)

---

[Previous page](../xWalkGPT/simulation/xWalkGPT%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkMusic/xWalkMusic.md)
