<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkVoice

**2. xWalk hardware &middot; Module 36**

<!-- xwalk-page-header:end -->

# xWalkVoice

`xWalkVoice` groups the xWalk Agent coordinators for the local chatbot, spoken movement, storytelling,
voice control, vision-language conversation, online language-model conversation, voice-active car, and GPT-car
profiles. It exports one interface target and provides group-level host and hardware-profile tests.

## 1. Overview

Consumers can link `xWalk::AgentVoice` to obtain every voice child module. The child modules remain distinct
because they have different wake profiles, model providers, prompt flows, and hardware dependencies. Each child
binds caller-owned HAL or Agent objects; the process composition layer in `xWalkController` selects and owns the
microphone, recognizer, language model, speech synthesizer, camera, and vehicle resources.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice` (source directory)

## 3. Directory layout

```text
xWalkVoice/
    CMakeLists.txt                  Group project, xWalk::AgentVoice interface target, and group tests
    test/
        src/                        Host group test that checks each child module
        hardware/src/               Hardware-profile group test (compile-time type checks)
    xWalkGptCar/                    gpt_examples profile on the shared voice-active car coordinator
    xWalkLocalVoiceChatbot/         Local listen, think, and speak chatbot loop
    xWalkOnlineLlmTest/             Typed text-only language-model conversation
    xWalkStorytellingRobot/         Narrated forward and return movement sequence
    xWalkTextVisionTalk/            Typed prompts grounded by a newly captured image
    xWalkVoiceActiveCar/            Shared wake-word voice car coordinator and configuration
    xWalkVoiceActiveCarGpt/         Local-model profile of the voice-active car
    xWalkVoiceControlledCar/        Wake-word keyword vehicle control
    xWalkVoicePromptCar/            Spoken movement prompts
```

## 4. Child modules

- [xWalkGptCar](xWalkGptCar/xWalkGptCar.md): upstream `gpt_examples` profile delegated to the shared
  voice-active car coordinator.
- [xWalkLocalVoiceChatbot](xWalkLocalVoiceChatbot/xWalkLocalVoiceChatbot.md): foreground local voice chatbot
  that removes hidden-thinking sections before speech.
- [xWalkOnlineLlmTest](xWalkOnlineLlmTest/xWalkOnlineLlmTest.md): typed text-only conversation through a
  caller-owned language model.
- [xWalkStorytellingRobot](xWalkStorytellingRobot/xWalkStorytellingRobot.md): spoken jokes with bounded
  forward and backward movement.
- [xWalkTextVisionTalk](xWalkTextVisionTalk/xWalkTextVisionTalk.md): typed prompts sent with a newly captured
  camera image.
- [xWalkVoiceActiveCar](xWalkVoiceActiveCar/xWalkVoiceActiveCar.md): shared voice-active car coordinator.
- [xWalkVoiceActiveCarGpt](xWalkVoiceActiveCarGpt/xWalkVoiceActiveCarGpt.md): local-model voice-active car
  profile.
- [xWalkVoiceControlledCar](xWalkVoiceControlledCar/xWalkVoiceControlledCar.md): wake-word and keyword vehicle
  control.
- [xWalkVoicePromptCar](xWalkVoicePromptCar/xWalkVoicePromptCar.md): spoken movement prompt sequence.

## 5. Public interface

| Target | Alias | Contents |
| --- | --- | --- |
| `xWalkDriverVoice` | `xWalk::AgentVoice` | `INTERFACE` library linking all nine child libraries, C++17 |

Public headers belong to the child modules; see each child note.

## 6. Build

The group options are `OFF` by default:

| Option | Effect |
| --- | --- |
| `XWALK_AGENT_VOICE_BUILD_HOST_TESTS` | Builds `xWalkDriverVoiceGroupTest` and enables the child host tests |
| `XWALK_AGENT_VOICE_BUILD_HARDWARE_TESTS` | Builds `xWalkDriverVoiceGroupHardwareTest` |

Enabling the host option forces `XWALK_LOCAL_VOICE_CHATBOT_BUILD_HOST_TESTS`,
`XWALK_VOICE_ACTIVE_CAR_BUILD_HOST_TESTS`, `XWALK_VOICE_ACTIVE_CAR_GPT_BUILD_HOST_TESTS`, and
`XWALK_GPT_CAR_BUILD_HOST_TESTS` to `ON`. Either option includes
`XWalkDependencies.cmake` and requires
GoogleTest. The `xWalkDriver` aggregate sets both group options from `XWALK_AGENT_BUILD_HOST` and
`XWALK_AGENT_BUILD_RPI`.

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver/xWalkVoice -B xWalk-rpi5-hw/xWalkDriver/xWalkVoice/build-host -DXWALK_AGENT_VOICE_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/xWalkVoice/build-host --parallel
```

## 7. Testing

`xWalkDriverVoiceGroupHostTest` (labels `host;agent-group`) runs one GoogleTest case per child module. Cases for
`xWalkLocalVoiceChatbot`, `xWalkVoiceActiveCar`, `xWalkVoiceActiveCarGpt`, and `xWalkGptCar` execute the child
host-test executable in an isolated process; the remaining cases check device-free configuration defaults and
command classification.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/xWalkVoice/build-host --output-on-failure -L host
```

`xWalkDriverVoiceGroupHardwareTest` (labels `hardware;agent-group`) is opt-in and is built in a separate
directory configured with `-DXWALK_AGENT_VOICE_BUILD_HARDWARE_TESTS=ON`. List it without running it:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/xWalkVoice/build-rpi -N -L hardware
```

Run hardware tests only with explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- Child modules and their HAL dependencies, added through each child `CMakeLists.txt`.
- GoogleTest and the shared group test support header `xAgent_Rpi5CarGroupTestSupport.h` in
  `xWalkDriver/test/include` for the group host test.

## 9. Safety and constraints

Every voice child module owns a registered `RPIAGENT` lifecycle or bounded-operation trace. Use the
authoritative [Agent trace table](../xWalkDriver.md#runtime-tracing) to select one child. Traces exclude
recognized speech, prompts, model-response text, spoken text, credentials, and images.

## 10. Related notes

- [xWalkDriver](../xWalkDriver.md)
- [xWalkVoiceAssistant](../../xWalkHal/layer1/xWalkVoiceAssistant/xWalkVoiceAssistant.md)
- [xWalkLanguageModel](../../xWalkHal/interface/xWalkLanguageModel/xWalkLanguageModel.md)
- xWalkBoot source directory

---

[Previous page](../xWalkVision/test/assets/xWalkVision%20Test%20Assets.md) · [Chapter index](../../../index.md) · [Next page](xWalkGptCar/xWalkGptCar.md)
