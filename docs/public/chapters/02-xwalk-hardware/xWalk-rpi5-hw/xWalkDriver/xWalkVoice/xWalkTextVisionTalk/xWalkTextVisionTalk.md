<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkTextVisionTalk

**2. xWalk hardware &middot; Module 41**

<!-- xwalk-page-header:end -->

# xWalkTextVisionTalk

`xWalkTextVisionTalk` ports upstream `example/17.text_vision_talk.py` through caller-owned camera-capture and
language-model services. It applies the source instructions, welcome text, and 20-message conversation limit,
waits two seconds for camera warm-up, and captures a new image for every typed prompt until `exit` or `quit`.

## 1. Overview

`run()` sets the retained-message limit, instructions, and welcome on the language model, waits
`cameraWarmupMs`, and prints the welcome. Each round then:

1. reads one prompt through the input callback;
2. ends the loop when the trimmed, lower-cased prompt is `exit` or `quit`;
3. captures a new image through `XWalkCameraCapture::capture()`;
4. submits the prompt with the captured image path and writes the response through the output callback.

Continuation is checked before input, after input, after capture, and after the model response. `run()` returns
zero. The provider-neutral HAL returns a complete response, so the output callback receives one final response
line instead of Python word fragments. `stop()` has no effect because model and capture calls are synchronous.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkTextVisionTalk`
(source directory)

## 3. Directory layout

```text
xWalkTextVisionTalk/
    CMakeLists.txt                                  Static library and alias
    include/
        xAgent_Rpi5CarTextVisionTalk.h              Coordinator class
        xAgent_Rpi5CarTextVisionTalkTypes.h         Callbacks and example 17 configuration
    src/
        xAgent_Rpi5CarTextVisionTalk.cpp            Prompt, capture, and response loop
        xAgent_Rpi5CarTextVisionTalkLifecycle.cpp   Construction, normalization, and validation
```

## 4. Public interface

Headers `xAgent_Rpi5CarTextVisionTalk.h` and `xAgent_Rpi5CarTextVisionTalkTypes.h`
are in the
include directory.

| Element | Contract |
| --- | --- |
| Constructor | Binds caller-owned `hal::XWalkLanguageModel` and `XWalkCameraCapture`, context, callbacks |
| `run()` | Runs image-grounded prompts until `exit`, `quit`, or cancellation; returns zero |
| `stop()` | `noexcept`; no shutdown is required |

`XWalkTextVisionTalkCallbacks` contains `output`, `input`, `delay` (milliseconds), and `shouldContinue`; all are
required. `XWalkTextVisionTalkConfiguration` defaults:

| Field | Default |
| --- | --- |
| `instructions` | `You are a helpful assistant.` |
| `welcome` | `Hello, I am a helpful assistant. How can I help you?` |
| `promptText` | `>>> ` |
| `maximumMessages` | 20 (must be non-zero) |
| `cameraWarmupMs` | 2 000 ms (must be non-zero) |

The language model, camera capture, and context are non-owning and must outlive the coordinator and callback
use. The destructor releases nothing. Copy and move operations are deleted.

## 5. Build

CMake target `xWalkTextVisionTalk` (alias `xWalk::TextVisionTalk`) is a C++17 static library. When
`xWalkCameraCapture` or `xWalkLanguageModel` is not already defined, the project adds it with its tests and the
Ollama provider disabled. The module defines no standalone test option; build it through the voice group or the
`xWalkDriver` aggregate.

## 6. Configuration

Construction raises an invalid-argument error for a missing callback or an empty prompt text, and an
out-of-range error when `maximumMessages` or `cameraWarmupMs` is zero.

The Raspberry Pi composition in `xWalkBoot` binds a dedicated vision language model that defaults to Ollama at
`http://127.0.0.1:11434/api/chat` with model `llava:7b` (`text_vision_ollama_endpoint`,
`text_vision_ollama_model`, `text_vision_timeout_ms`), and the shared `XWalkCameraCapture`. The tracked
`features.conf`
also declares the example 17 image path `/tmp/llm-img.jpg` and a 1280-by-720 capture size. The image path and
resolution are properties of the camera-capture composition, not of this coordinator.

## 7. Testing

The module has no own test executable. The voice group host test case `XWalkAgentVoiceGroup.TextVisionTalk`
checks the 20-message limit, the 2 000 ms warm-up, and a non-empty welcome:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/xWalkVoice/build-host --output-on-failure -L host
```

The voice group hardware-profile test only checks that the class type is available; list it with
`ctest -N -L hardware` and never run it without explicit approval and a confirmed safe Raspberry Pi and Robot
HAT setup.

## 8. Dependencies

- `xWalkCameraCapture` (public) from `xWalkDriver/xWalkVision/xWalkCameraCapture`.
- `xWalkLanguageModel` (public) from `xWalkHal/interface/xWalkLanguageModel`.
- `xWalkTrace` (private) for the `RPIAGENT.041` lifecycle trace, which records only the message bound.

## 9. Safety and constraints

- The coordinator captures camera images but drives no motors or servos.
- Traces exclude prompts, model-response text, and images.

## 10. Related notes

- [xWalkVoice](../xWalkVoice.md)
- [xWalkCameraCapture](../../xWalkVision/xWalkCameraCapture/xWalkCameraCapture.md)
- [xWalkLanguageModel](../../../xWalkHal/interface/xWalkLanguageModel/xWalkLanguageModel.md)
- xWalkBoot source directory
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkStorytellingRobot/xWalkStorytellingRobot.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkVoiceActiveCar/xWalkVoiceActiveCar.md)
