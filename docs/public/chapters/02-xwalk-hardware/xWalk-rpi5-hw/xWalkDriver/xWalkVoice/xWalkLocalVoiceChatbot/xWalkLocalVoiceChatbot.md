<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkLocalVoiceChatbot

**2. xWalk hardware &middot; Module 38**

<!-- xwalk-page-header:end -->

# xWalkLocalVoiceChatbot

`xWalkLocalVoiceChatbot` is a hardware-independent foreground Agent coordinator. It repeatedly listens through a
caller-owned `XWalkVoiceAssistant`, prompts its language model, removes hidden-thinking sections, speaks one
clean response, handles silence, and stops recognition on completion. It preserves the visible messages from
`example/19.local_voice_chatbot.py`.

## 1. Overview

Each round of `run()`:

1. checks continuation, prints the listening message, and listens with the configured timeout;
2. on empty recognition, prints the silence message and delays 100 ms;
3. otherwise prints `[YOU] <text>`, calls the assistant model, prints the raw response, speaks the response
   after `stripThinking()` (or the empty-response fallback), and delays 50 ms.

The welcome is printed after the assistant starts. On loop exit the coordinator prints the stopping message,
speaks the goodbye only while continuation is still permitted, stops the assistant, and prints `Bye.`.

Cancellation is checked after recognition and inference and before optional farewell speech. A cancelled round
does not start another model request or speak its response or goodbye. Recognition shutdown still runs. When
completion still permits speech, the existing goodbye text is preserved. The controller binds its operation
latch to the existing HTTP language-model and Piper providers so they also observe cancellation during their
work. Other synchronous providers retain their own cancellation or timeout boundaries.

`stripThinking()` removes paired `<think>` and `<thinking>` sections and `[thinking]` and `[/thinking]` markers,
then trims the result.

The module owns no microphone, recognizer, language model, network transport, speech synthesizer, ALSA stream,
Robot HAT GPIO, thread, or signal handler. Those resources remain selected by the process composition layer.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkLocalVoiceChatbot`
(source directory)

## 3. Directory layout

```text
xWalkLocalVoiceChatbot/
    CMakeLists.txt                                      Static library, alias, and optional host test
    include/
        xAgent_Rpi5CarLocalVoiceChatbot.h               Coordinator class
        xAgent_Rpi5CarLocalVoiceChatbotTypes.h          Callbacks, configuration, and default messages
    src/
        xAgent_Rpi5CarLocalVoiceChatbotLifecycle.cpp    Construction, validation, run loop, and shutdown
        xAgent_Rpi5CarLocalVoiceChatbotResponse.cpp     Hidden-thinking removal
    test/
        include/xAgent_Rpi5CarLocalVoiceChatbotTestSupport.h    Fake session state and callback declarations
        src/xAgent_Rpi5CarLocalVoiceChatbotTestSupport.cpp      Callback implementations and composition
        src/xAgent_Rpi5CarLocalVoiceChatbotTest.cpp             Scenario assertions
```

## 4. Public interface

Headers `xAgent_Rpi5CarLocalVoiceChatbot.h` and `xAgent_Rpi5CarLocalVoiceChatbotTypes.h`
are in the
include directory.

| Element | Contract |
| --- | --- |
| Constructor | Binds a caller-owned `hal::XWalkVoiceAssistant`, a nullable context, callbacks, and configuration |
| `run()` | Runs rounds until cancellation; returns zero after orderly shutdown |
| `stop()` | Stops the assistant |
| `stripThinking(response)` | Returns the trimmed response without hidden-thinking content |
| Destructor | Stops the caller-owned assistant without releasing it |

`XWalkLocalVoiceChatbotCallbacks` contains `output`, `shouldContinue`, and `delay` (milliseconds); all are
required. `XWalkLocalVoiceChatbotConfiguration` holds the welcome, listening, silence, empty-response, stopping,
goodbye, and `Bye.` messages, and `listenTimeoutMs` (default 10 000 ms).

The assistant and context are non-owning and must outlive the coordinator and callback use. Copy and move
operations are deleted. `run()` propagates callback and voice-pipeline exceptions; the destructor stops the
assistant during stack unwinding.

## 5. Build

CMake target `xWalkLocalVoiceChatbot` (alias `xWalk::LocalVoiceChatbot`) is a C++17 static library. When
`xWalkVoiceAssistant` is not already defined, the project adds it with its host and hardware tests disabled.

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_LOCAL_VOICE_CHATBOT_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkLocalVoiceChatbotTest` |

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkLocalVoiceChatbot -B xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkLocalVoiceChatbot/build-host -DXWALK_LOCAL_VOICE_CHATBOT_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkLocalVoiceChatbot/build-host --parallel
```

## 6. Configuration

Construction validates the callbacks and configuration:

- a missing callback or an empty message raises an invalid-argument error;
- `listenTimeoutMs` must be in the range 1 to `XHAL_RPI5CAR_SPEECH_TO_TEXT_MAXIMUM_TIMEOUT_MS` (300 000 ms);
  otherwise an out-of-range error is raised.

The Raspberry Pi composition in `xWalkBoot` binds the shared `XWalkVoiceAssistant`, which uses Vosk with the
configured English model and Piper with the deployment-selected `.onnx` model, and the generic
`voice_language_model_*` provider (local Ollama by default). The tracked
`features.conf`
declares the example 19 defaults: Ollama `llama3.2:3b` at `http://127.0.0.1:11434/api/chat`, a 20-message
history matching the source example, and a Piper model path. Provider paths and model names remain deployment
configurable without being owned by this coordinator.

## 7. Testing

`xWalkLocalVoiceChatbotHostTest` (label `host`) is a device-free `assert`-based executable. Scenario assertions
are in `test/src/xAgent_Rpi5CarLocalVoiceChatbotTest.cpp`; reusable fake session state and callback declarations
are in `test/include/xAgent_Rpi5CarLocalVoiceChatbotTestSupport.h`; callback implementations and device-free
composition are in `test/src/xAgent_Rpi5CarLocalVoiceChatbotTestSupport.cpp`. The session fixture is
independent of how often the coordinator queries continuation. Scenarios cover a complete round, cancellation
after recognition, cancellation after inference, and hidden-thinking removal.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkLocalVoiceChatbot/build-host --output-on-failure
```

The voice group host test also runs this executable. Hardware-profile coverage is limited to the voice group
hardware test; list it with `ctest -N -L hardware` and never run it without explicit approval and a confirmed
safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- `xWalkVoiceAssistant` (public) from `xWalkHal/layer1/xWalkVoiceAssistant`.
- `xWalkTrace` (private) for the `RPIAGENT.038` lifecycle trace and the `RPIAGENT.085` response-filtering trace.

## 9. Safety and constraints

- The coordinator is synchronous and runs in the caller's foreground thread.
- Traces exclude recognized speech, prompts, model-response text, and spoken text.

## 10. Related notes

- [xWalkVoice](../xWalkVoice.md)
- [xWalkVoiceAssistant](../../../xWalkHal/layer1/xWalkVoiceAssistant/xWalkVoiceAssistant.md)
- xWalkBoot source directory
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkGptCar/xWalkGptCar.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkOnlineLlmTest/xWalkOnlineLlmTest.md)
