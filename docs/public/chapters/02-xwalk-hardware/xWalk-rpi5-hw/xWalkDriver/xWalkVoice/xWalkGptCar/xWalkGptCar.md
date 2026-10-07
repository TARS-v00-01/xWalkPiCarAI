<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkGptCar

**2. xWalk hardware &middot; Module 37**

<!-- xwalk-page-header:end -->

# xWalkGptCar

`xWalkGptCar` ports the upstream `gpt_examples` application onto the shared `xWalkVoiceActiveCar` coordinator,
which in turn uses `xWalkSelfDrive` for preset actions. It supplies the assistant instructions and car defaults
and delegates the foreground loop to the shared coordinator.

## 1. Overview

The profile preserves voice or keyboard input, optional camera context, the JSON `actions` and `answer`
contract, the complete preset-action vocabulary, and the two sound effects:

- actions: shake head, nod, wave hands, resist, act cute, rub hands, think, twist body, celebrate, depressed;
- sound effects: honking, start engine.

`carConfiguration()` enables image attachment, selects voice input and the JSON response format, and disables
autonomous ultrasonic prompting. `configure()` switches between keyboard and voice input and enables or disables
the image for the next run.

The profile constants select the OpenAI-compatible chat endpoint
`https://api.openai.com/v1/chat/completions` with model `gpt-4o`. `OPENAI_API_KEY` exclusively supplies the
credential; the assistant configuration contains no credential. The source text-to-speech voice `echo` is
retained as profile metadata. The upstream Assistants identifier and generated speech files are not persisted
by this adapter.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkGptCar`
(source directory)

## 3. Directory layout

```text
xWalkGptCar/
    CMakeLists.txt                          Static library, alias, and optional host test
    include/xAgent_Rpi5CarGptCar.h          Profile class, provider constants, and execution adapter
    src/xAgent_Rpi5CarGptCar.cpp            Instructions, JSON-mode configuration, and delegation
    test/src/xAgent_Rpi5CarGptCarTest.cpp   Device-free profile and JSON parsing checks
```

## 4. Public interface

Header `xAgent_Rpi5CarGptCar.h` is in the
include directory.

| Member | Behavior |
| --- | --- |
| `MODEL_NAME`, `MODEL_ENDPOINT` | `gpt-4o` and the OpenAI chat-completions endpoint |
| `API_KEY_ENVIRONMENT` | `OPENAI_API_KEY` |
| `SPEECH_VOICE` | Source text-to-speech voice `echo`, kept as metadata |
| `assistantConfiguration()` | Returns the upstream instructions with no welcome speech |
| `carConfiguration()` | Returns JSON, image-enabled, voice-input defaults with sensor prompting disabled |
| `configure(keyboardInput, withImage)` | Sets input mode and image use on the shared coordinator |
| `run()` | Delegates to `XWalkVoiceActiveCar::run()` until application cancellation |
| `stop()` | Delegates to `XWalkVoiceActiveCar::stop()` for assistant, action, LED, and vehicle activity |

`XWalkGptCar` stores a non-owning pointer to a caller-created `XWalkVoiceActiveCar`. The coordinator and all
of its dependencies must outlive the adapter. The destructor neither stops nor releases the dependency. Copy and
move operations are deleted.

## 5. Build

CMake target `xWalkGptCar` (alias `xWalk::GptCar`) is a C++17 static library. When `xWalkVoiceActiveCar` is not
already defined, the project adds it with its host tests disabled.

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_GPT_CAR_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkGptCarTest` |

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkGptCar -B xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkGptCar/build-host -DXWALK_GPT_CAR_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkGptCar/build-host --parallel
```

## 6. Configuration

The Raspberry Pi composition in `xWalkBoot` constructs `XWalkGptCar` over the shared `XWalkVoiceActiveCar`
instance. The tracked controller configuration
`features.conf`
declares the `gpt_car_*` profile keys (endpoint, `gpt-4o`, `OPENAI_API_KEY`, maximum output tokens 1024).

## 7. Testing

`xWalkGptCarHostTest` (label `host`) is a device-free `assert`-based executable. It checks the instructions,
the JSON image-enabled car defaults, and parsing of a JSON response with two actions.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkGptCar/build-host --output-on-failure -L host
```

The voice group test also runs this executable. The group hardware-profile test only checks that the class
type is available; list it with `ctest -N -L hardware` and never run it without explicit approval and a
confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- `xWalkVoiceActiveCar` (public), which links `xWalkSelfDrive`, `xWalkVoiceAssistant`, `xWalkLed`, and
  `xWalkWebSearch`.
- `xWalkTrace` (private) for the `RPIAGENT.037` delegation trace.

## 9. Safety and constraints

- Never pass the API key through command arguments or committed configuration; only `OPENAI_API_KEY` supplies
  it.
- Vehicle motion, actions, and LED behavior are owned by the shared coordinator; `stop()` delegates to it.
- Traces exclude prompts, responses, credentials, and images.

## 10. Related notes

- [xWalkVoice](../xWalkVoice.md)
- [xWalkVoiceActiveCar](../xWalkVoiceActiveCar/xWalkVoiceActiveCar.md)
- [xWalkSelfDrive](../../xWalkVehicle/xWalkSelfDrive/xWalkSelfDrive.md)
- xWalkBoot source directory
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkVoice.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkLocalVoiceChatbot/xWalkLocalVoiceChatbot.md)
