<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkLanguageModel

**2. xWalk hardware &middot; Module 79**

<!-- xwalk-page-header:end -->

# xWalkLanguageModel

`xWalkLanguageModel` provides C++17 embedded-oriented, provider-neutral language-model coordination behind one
injected backend, plus an optional bounded HTTP provider for Ollama and OpenAI-compatible endpoints.

## 1. Overview

The public interface consolidates general, Deepseek, Grok, Doubao, Gemini, Qwen, OpenAI, and Ollama
conversation behavior behind one injected backend instead of embedding provider SDKs in the firmware layer.

`XWalkLanguageModelHttp` is the compatibility name for the concrete bounded HTTP backend. The legacy
`XWalkLanguageModelOllama` class name remains source and ABI compatible. Create the backend before the
coordinator and pass it as callback context:

```cpp
XWalkLanguageModelHttp backend("http://127.0.0.1:11434/api/chat", "gemma3");
XWalkLanguageModel languageModel(&backend, backend.callbacks());
languageModel.setInstructions("Answer briefly.");
const string response = languageModel.prompt("Hello");
```

The provider owns its dialect, endpoint, model name, optional API key, instructions, welcome text, encoded
images, and bounded conversation history. Real requests use libcurl with either the non-streaming Ollama
`/api/chat` contract (`XWalkLanguageModelHttpDialect::Ollama`) or an authenticated OpenAI-compatible
`/chat/completions` contract (`XWalkLanguageModelHttpDialect::OpenAiChatCompletions`). Calls require external
serialization. An injected HTTP operation supports deterministic tests and alternate transports.

The OpenAI-compatible dialect is used for ChatGPT, Gemini's compatibility API, Claude's compatibility API, and
explicitly compatible private services. The deployment supplies the complete endpoint and model name; the
firmware does not guess either value. The provider follows Ollama's documented non-streaming chat request and
final `message.content` response shape.

### Coordinator behavior

- `setInstructions()` replaces system instructions.
- `setWelcome()` replaces conversation welcome text.
- `setMaximumMessages()` configures a non-zero retained-message limit; the default is 20 messages.
- `addMessage()` supports system, user, and assistant roles.
- `addMessage()` and `prompt()` accept an optional image path.
- `prompt()` returns one owned final response and preserves empty responses.
- Empty instructions, welcome text, message content, and prompt text are preserved.

### Image capability check

Before reading or sending an image, the local Ollama provider queries bounded `/api/show` metadata and requires
an explicit `vision` capability. Missing or malformed capability metadata rejects the image request. Text-only
requests and the OpenAI-compatible dialect do not perform this Ollama-specific lookup. Unsuccessful HTTP
diagnostics exclude provider response details.

### In-flight cancellation

`setCancellation()` borrows the operation owner's atomic latch while the provider is idle. The owner must keep
the latch alive through every call and reset it before admitting a new operation. Injected POST operations
receive the same nullable latch. The system transport polls libcurl multi transfers at most every 50 ms and
checks retry waits in 20 ms slices; the configured inference timeout is unchanged. Cancellation releases curl
resources and throws `XWalkOperationCancelled` without an error trace or successful history entry. Terminal
HTTP/JSON failures retain their existing error path even with cancellation pending.

Hostname resolution needs an asynchronous-DNS libcurl build; a synchronous resolver remains a blocking boundary.
Other injected transports must implement their cancellation contract themselves. Cancellation closes the client
HTTP transfer. Server-side inference termination is provider-dependent and has not been independently verified
by the host fixture. The Controller does not terminate model-server processes.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel` -
source directory

## 3. Directory layout

```text
xWalkLanguageModel/
    CMakeLists.txt                                         Coordinator, provider, and test targets
    include/
        xHal_Rpi5CarLanguageModel.h                        Provider-neutral coordinator
        xHal_Rpi5CarLanguageModelTypes.h                   Roles and backend callback table
    src/
        xHal_Rpi5CarLanguageModel.cpp                      Coordinator operations
        xHal_Rpi5CarLanguageModelLifecycle.cpp             Callback validation and construction
    hardware/
        include/xHal_Rpi5CarLanguageModelOllama.h          Bounded HTTP provider class
        include/xHal_Rpi5CarLanguageModelOllamaTypes.h     Dialect, message, response, and operation types
        src/xHal_Rpi5CarLanguageModelOllamaCallbacks.cpp   Coordinator callback bridge
        src/xHal_Rpi5CarLanguageModelOllamaJson.cpp        Request and response JSON handling
        src/xHal_Rpi5CarLanguageModelOllamaLifecycle.cpp   Provider validation and construction
        src/xHal_Rpi5CarLanguageModelOllamaSystem.cpp      libcurl transport, retry, and cancellation
        test/include/                                      Provider test support and types
        test/src/xHal_Rpi5CarLanguageModelOllamaTest.cpp   Provider host test with fake transport
        test/src/xHal_Rpi5CarLanguageModelOllamaTestSupport.cpp  Provider fake-transport implementation
        test/xHal_Rpi5CarLanguageModelHttpTest.py          Loopback HTTP cancellation fixture
    simulation/                                            Network-free standalone simulation
    test/
        include/xHal_Rpi5CarLanguageModelTestSupport.h     Coordinator test support declarations
        src/xHal_Rpi5CarLanguageModelTest.cpp              Coordinator host test
        src/xHal_Rpi5CarLanguageModelTestSupport.cpp       Coordinator test support implementation
        hardware/src/xHal_Rpi5CarLanguageModelHardwareTest.cpp   Opt-in single-request provider test
```

## 4. Child modules

- [xWalkLanguageModel Simulation](simulation/xWalkLanguageModel%20Simulation.md) - network-free standalone
  executable that exercises the coordinator through an in-memory backend.

## 5. Public interface

Headers live in `include` and
`hardware/include`.

- `xHal_Rpi5CarLanguageModel.h`:
  `XWalkLanguageModel(context, callbacks)`, `setInstructions`, `setWelcome`, `setMaximumMessages`,
  `addMessage`, and `prompt`.
- `xHal_Rpi5CarLanguageModelTypes.h`:
  `XWalkLanguageModelRole` and `XWalkLanguageModelCallbacks`.
- `xHal_Rpi5CarLanguageModelOllama.h`:
  `XWalkLanguageModelOllama` (alias `XWalkLanguageModelHttp`) with `callbacks()` and `setCancellation()`.

The provider enforces these limits, defined in the common library header `xHal_Rpi5CarCommon.h`:

| Limit | Value |
| --- | --- |
| Retained messages | 200 maximum, 20 by default |
| Model, endpoint, instruction, welcome, message, or response content value | 256 KiB each |
| Raw image (encoded immediately as base64) | 4 MiB |
| Serialized JSON request | 8 MiB |
| HTTP response | 1 MiB |
| Request timeout | 1 through 300,000 ms, 120,000 ms by default |
| API key | 8,192 bytes |
| Output tokens (compatible dialect) | 1,024 by default, 1,000,000 maximum |

## 6. Build

| Target | Kind | Condition |
| --- | --- | --- |
| `xWalkLanguageModel` | Static coordinator library | Always |
| `xWalkLanguageModelOllama` | Static HTTP provider linking libcurl and json-c | Any option below is `ON` |
| `xWalkLanguageModelTest` | Coordinator host test | `XWALK_LANGUAGE_MODEL_BUILD_HOST_TESTS` |
| `xWalkLanguageModelOllamaTest` | Provider host test | `XWALK_LANGUAGE_MODEL_BUILD_HOST_TESTS` |
| `xWalkLanguageModelHardwareTest` | Single-request provider test | `XWALK_LANGUAGE_MODEL_BUILD_HARDWARE_TESTS` |

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_LANGUAGE_MODEL_BUILD_HOST_TESTS` | `OFF` | Builds coordinator and provider host tests |
| `XWALK_LANGUAGE_MODEL_BUILD_HARDWARE_TESTS` | `OFF` | Builds the opt-in provider request test |
| `XWALK_LANGUAGE_MODEL_BUILD_OLLAMA_PROVIDER` | `OFF` | Builds `xWalkLanguageModelOllama` without tests |

The repository-level `xWalk-rpi5-hw/CMakeLists.txt` also adds this module to the aggregate build.

## 7. Testing

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel -B xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/build-host -DXWALK_LANGUAGE_MODEL_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/build-host -L host --output-on-failure
```

| CTest name | Label | Scope |
| --- | --- | --- |
| `xWalkLanguageModelHostTest` | `host` | Coordinator behavior, trace selectors, and persistent XML |
| `xWalkLanguageModelOllamaHostTest` | `host` | Provider with fake HTTP transport and a three-byte test image |
| `xWalkLanguageModelHttpCancellationHostTest` | `host` | Production libcurl, loopback fixture, 20 s timeout |

The provider host test performs no model, credential, process, or external network operation. Its fake transport
state and callbacks live in `xwalk::hal::test::ollama`, with the support source explicitly included in
standalone and aggregate test targets. Reusable coordinator callback state and operations live in the named
`xwalk::hal::test::language_model` support component instead of the test body.

The Python cancellation test starts a `127.0.0.1` HTTP fixture with an ephemeral port. The stalled-loopback
regression requires transfer cancellation within two seconds and verifies subsequent provider reuse. This is a
host acceptance bound, not a Raspberry Pi measurement. No test uses an external model service.

The hardware-labelled test `xWalkLanguageModelOllamaHardwareTest` requires an explicit endpoint, model, and
prompt, then performs exactly one bounded request without printing its content. CTest registers no arguments, so
normal verification only lists it:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel -B xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/build-rpi -DXWALK_LANGUAGE_MODEL_BUILD_HARDWARE_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/build-rpi -N -L hardware
```

Run the executable manually only after approving the endpoint, model, prompt, and network policy:

```bash
xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/build-rpi/xWalkLanguageModelHardwareTest <endpoint/api/chat> <model> <prompt>
```

The aggregate [xWalkHal Interface Tests](../test/xWalkHal%20Interface%20Tests.md) and
[xWalkHal Layer1 Tests](../../layer1/test/xWalkHal%20Layer1%20Tests.md) suites reuse the coordinator test
support.

## 8. Dependencies

- `xWalkLibraryCommon` (public) and `xWalkTrace` (private).
- Provider only: libcurl (`find_package(CURL)`) and json-c through `pkg-config`.
- Python 3 for the trace catalogue and the loopback cancellation test.

## 9. Safety and constraints

- The native Ollama dialect sends no authorization header and is intended for an appropriately protected local
  or deployment-controlled endpoint.
- The compatible dialect requires HTTPS and sends the configured key only as an `Authorization: Bearer` header.
  The key is bounded, rejected when it contains control-line characters, and never copied into request JSON or
  conversation history.
- TLS, credential rotation, and network access policy remain deployment responsibilities.
- Request, response, image, and credential content must never be written to normal diagnostics. Normal traces
  report operation state only.

## 10. Related notes

- [xWalkHal Interface Layer](../xWalkHal%20Interface%20Layer.md)
- [xWalkVoiceAssistant](../../layer1/xWalkVoiceAssistant/xWalkVoiceAssistant.md)
- [xWalkOnlineLlmTest](../../../xWalkDriver/xWalkVoice/xWalkOnlineLlmTest/xWalkOnlineLlmTest.md)
- [xWalkTextVisionTalk](../../../xWalkDriver/xWalkVoice/xWalkTextVisionTalk/xWalkTextVisionTalk.md)

---

[Previous page](../xWalkI2c/test/xWalkI2c%20Tests.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkLanguageModel%20Simulation.md)
