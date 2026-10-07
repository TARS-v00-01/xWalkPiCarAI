<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkOnlineLlmTest

**2. xWalk hardware &middot; Module 39**

<!-- xwalk-page-header:end -->

# xWalkOnlineLlmTest

`xWalkOnlineLlmTest` ports upstream `example/18.online_llm_test.py` through a caller-owned language-model
service. It applies the source instructions, welcome text, and 20-message history limit, then submits typed
text-only prompts until process cancellation.

## 1. Overview

`run()` sets the retained-message limit, instructions, and welcome on the language model, prints the welcome,
and then loops: it reads one prompt through the input callback, submits it, and writes the response through the
output callback. Continuation is checked before input, after input, and after the model response, so a cancelled
round neither submits another prompt nor reports its response. `run()` returns zero.

The provider-neutral HAL returns a complete response, so the output callback receives one final response line
instead of Python stream fragments. `stop()` has no effect because every model call is synchronous.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkOnlineLlmTest`
(source directory)

## 3. Directory layout

```text
xWalkOnlineLlmTest/
    CMakeLists.txt                                  Static library and alias
    include/
        xAgent_Rpi5CarOnlineLlmTest.h               Coordinator class
        xAgent_Rpi5CarOnlineLlmTestTypes.h          Callbacks and example 18 configuration
    src/
        xAgent_Rpi5CarOnlineLlmTest.cpp             Prompt loop and stop
        xAgent_Rpi5CarOnlineLlmTestLifecycle.cpp    Construction and validation
```

## 4. Public interface

Headers `xAgent_Rpi5CarOnlineLlmTest.h` and `xAgent_Rpi5CarOnlineLlmTestTypes.h`
are in the
include directory.

| Element | Contract |
| --- | --- |
| Constructor | Binds a caller-owned `hal::XWalkLanguageModel`, a nullable context, callbacks, and configuration |
| `run()` | Runs typed text-only prompts until cancellation; returns zero |
| `stop()` | `noexcept`; no shutdown is required |

`XWalkOnlineLlmTestCallbacks` contains `output`, `input`, and `shouldContinue`; all are required.
`XWalkOnlineLlmTestConfiguration` defaults:

| Field | Default |
| --- | --- |
| `instructions` | `You are a helpful assistant.` |
| `welcome` | `Hello, I am a helpful assistant. How can I help you?` |
| `promptText` | `>>> ` |
| `maximumMessages` | 20 (must be non-zero) |

The language model and context are non-owning and must outlive the coordinator and callback use. The destructor
releases nothing. Copy and move operations are deleted.

## 5. Build

CMake target `xWalkOnlineLlmTest` (alias `xWalk::OnlineLlmTest`) is a C++17 static library. When
`xWalkLanguageModel` is not already defined, the project adds it with host tests, hardware tests, and the Ollama
provider disabled. The module defines no standalone test option; build it through the voice group or the
`xWalkDriver` aggregate.

## 6. Configuration

Construction raises an invalid-argument error for a missing callback or an empty prompt text, and an
out-of-range error when `maximumMessages` is zero.

The tracked controller configuration
`features.conf`
declares the example 18 defaults: OpenAI's chat-completions endpoint, model `gpt-4o`, and the credential
environment variable `OPENAI_API_KEY`. The credential is read only from the environment; it is never accepted in
command arguments, committed configuration, or diagnostics. The current `xWalkBoot` composition binds the shared
language model created from the generic `voice_language_model_*` provider settings.

## 7. Testing

The module has no own test executable. The voice group host test case `XWalkAgentVoiceGroup.OnlineLlmTest`
checks the default instructions and the 20-message limit:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/xWalkVoice/build-host --output-on-failure -L host
```

The voice group hardware-profile test only checks that the class type is available; list it with
`ctest -N -L hardware` and never run it without explicit approval and a confirmed safe Raspberry Pi and Robot
HAT setup.

## 8. Dependencies

- `xWalkLanguageModel` (public) from `xWalkHal/interface/xWalkLanguageModel`.
- `xWalkTrace` (private) for the `RPIAGENT.039` lifecycle trace, which records only the message bound.

## 9. Safety and constraints

- The module drives no hardware.
- Traces exclude prompts, model-response text, and credentials.

## 10. Related notes

- [xWalkVoice](../xWalkVoice.md)
- [xWalkLanguageModel](../../../xWalkHal/interface/xWalkLanguageModel/xWalkLanguageModel.md)
- xWalkBoot source directory
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkLocalVoiceChatbot/xWalkLocalVoiceChatbot.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkStorytellingRobot/xWalkStorytellingRobot.md)
