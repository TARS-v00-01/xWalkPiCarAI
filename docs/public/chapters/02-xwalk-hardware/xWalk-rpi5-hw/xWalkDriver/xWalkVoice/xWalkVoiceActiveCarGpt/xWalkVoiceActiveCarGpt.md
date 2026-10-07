<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkVoiceActiveCarGpt

**2. xWalk hardware &middot; Module 44**

<!-- xwalk-page-header:end -->

# xWalkVoiceActiveCarGpt

`xWalkVoiceActiveCarGpt` adapts upstream `example/21.voice_active_car_gpt.py` as the provider-neutral Jarvis
profile over the shared [`xWalkVoiceActiveCar`](../xWalkVoiceActiveCar/xWalkVoiceActiveCar.md) sensor and action
coordinator. The module supplies immutable defaults, the complete Jarvis instructions, and the coordinator
configuration; it contains no runtime loop of its own.

## 1. Overview

Jarvis retains the ten-centimetre ultrasonic trigger, English recognition profile, and bounded hardware
composition of the shared coordinator. It is permanently text-only after speech transcription and has no
camera input. The wake phrase is `hey jarvis`, the cinematic AI-style wake answer is
`Systems online. Ready when you are, [operator].`, and the welcome message is
`Hi, I'm Jarvis. Wake me up with: hey jarvis`.

### Model and voice

The Raspberry Pi composition defaults to local Ollama `llama3.2:3b` through `http://127.0.0.1:11434/api/chat`,
the independently trained British male Piper voice `en_GB-alan-medium`, Vosk microphone recognition, the Robot
HAT status LED, and the shared SelfDrive actions. Local Ollama requires no API key. Gemini remains an optional
HTTPS deployment and reads `GEMINI_API_KEY` only when selected. Jarvis requests concise, speech-friendly answers
and defaults to at most 256 output tokens without changing action syntax. The profile does not clone or
impersonate an actor's voice.

### Continuous conversation

The first `hey jarvis` opens a bounded continuous session. Follow-up requests do not repeat the wake phrase and
use the same language-model history. The session returns to wake mode after 30 seconds idle, ten successful
rounds, three consecutive recognition misses, cancellation, a terminal error, or one of the sleep phrases
`goodbye jarvis`, `go to sleep`, and `stop listening`. An explicit sleep phrase is acknowledged with
`Going to sleep. Say hey Jarvis when you need me, [operator].` Sleep phrases never reach the selected model or action
parsing. Session shutdown stops vehicle output.

Both wake and follow-up listens use incremental Vosk recognition. The installed Vosk C API has no
endpoint-timing setter, so the HAL speech-to-text backend uses native endpoints first and a
partial-transcript-armed trailing-silence fallback second. The 30-second listen timeout remains the hard safety
upper bound. Normal traces report timing decisions and transcript length without speech content; explicit
transcript tracing is privacy-sensitive and disabled by default.

### Camera policy

The owning application must construct the Jarvis service graph before reading camera configuration or
constructing a camera backend or capture Agent. The model always receives an empty image path. The tracked
`voice_active_car_gpt_with_image = false` setting is a validated policy lock; `true` is rejected rather than
enabling capture.

### Actions and answers

Jarvis may return only the exact locally allowlisted actions:

| Group | Actions |
| --- | --- |
| Direction | `forward`, `backward`, `stop` |
| Horn and sound | `honking`, `start engine` |
| Expressions | `shake head`, `nod`, `wave hands`, `resist`, `act cute`, `rub hands`, `think` |
| Gestures | `twist body`, `celebrate`, `depressed` |
| Background song | `play background music`, `stop background music` |

Unsupported action names are rejected by `XWalkSelfDrive`. Emoji remain response text and never become
executable actions. Each completed model response is split into spoken response text and filtered actions.
Piper synthesizes the response through the configured playback device while the SelfDrive worker executes
accepted actions.

Jarvis also answers ordinary safe questions from local model knowledge; a question does not need to request
vehicle movement. For a conversational answer, the model puts the answer in the response-text section and
emits `stop` as the fail-safe action. Every spoken or keyboard-chat response addresses the user as [operator]. The
action metadata is never spoken and cannot expand the local allowlist. Local answers do not imply internet
access, and Jarvis admits when current facts cannot be verified.

### Current-information retrieval

Optional current-information retrieval uses only a deployment-controlled, loopback SearXNG `/search` JSON
endpoint (default `http://127.0.0.1:8080/search`, at most 3 results, 5000 ms, 262 144 response bytes). The HAL
client bounds time, bytes, and result count, strips markup, rejects unsafe result URLs, never follows result
links, and marks reference text as untrusted. Retrieval-assisted rounds force the local `stop` action so web
content cannot move the vehicle. Search failure does not terminate Jarvis and does not fabricate current facts
or citations. `carConfiguration()` leaves `webSearchEnabled` off; the Raspberry Pi composition enables it from
deployment configuration.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkVoiceActiveCarGpt` -
source directory

## 3. Directory layout

```text
xWalkVoiceActiveCarGpt/
    CMakeLists.txt                                   Library and host test
    include/
        xAgent_Rpi5CarVoiceActiveCarGpt.h            Immutable example-21 defaults
    src/
        xAgent_Rpi5CarVoiceActiveCarGpt.cpp          Full prompt and profile construction
    test/
        src/xAgent_Rpi5CarVoiceActiveCarGptTest.cpp  Device-free profile verification
```

## 4. Public interface

`xAgent_Rpi5CarVoiceActiveCarGpt.h` in the
`include` directory
declares the final class
`xwalk::agent::XWalkVoiceActiveCarGpt` with two static functions:

- `assistantConfiguration()` returns the Jarvis instructions and welcome message;
- `carConfiguration()` returns an `XWalkVoiceActiveCarConfiguration` for the shared coordinator.

| Constant | Value |
| --- | --- |
| `NAME` | `Jarvis` |
| `SPEECH_LANGUAGE` | `en-us` |
| `SPEECH_VOICE` | `/usr/share/xwalk/models/piper/en_GB-alan-medium.onnx` |
| `MODEL_PROVIDER`, `MODEL_NAME` | `ollama`, `llama3.2:3b` |
| `MODEL_ENDPOINT` | `http://127.0.0.1:11434/api/chat` |
| `API_KEY_ENVIRONMENT` | Empty |
| `MODEL_TIMEOUT_MS` | 120 000 ms |
| `MAXIMUM_MESSAGES`, `MAXIMUM_OUTPUT_TOKENS` | 20, 256 |
| `WITH_IMAGE` | `false` |
| `CONTINUOUS_CONVERSATION` | `true` |
| `CONVERSATION_IDLE_TIMEOUT_MS` | 30 000 ms |
| `CONVERSATION_MAXIMUM_ROUNDS`, `CONVERSATION_MAXIMUM_MISSES` | 10, 3 |
| `SLEEP_PHRASES` | `goodbye jarvis,go to sleep,stop listening` |
| `WEB_SEARCH_ENABLED` | `true` |
| `WEB_SEARCH_ENDPOINT` | `http://127.0.0.1:8080/search` |
| `WEB_SEARCH_MAXIMUM_RESULTS`, `WEB_SEARCH_TIMEOUT_MS` | 3, 5000 ms |
| `WEB_SEARCH_MAXIMUM_RESPONSE_BYTES` | 262 144 bytes |
| `WAKE_WORD`, `ANSWER_ON_WAKE` | `hey jarvis`, `Systems online. Ready when you are, [operator].` |

`carConfiguration()` sets a 10 cm trigger, image attachment off, a 30 000 ms listen timeout, wake mode on, and
the continuous-session limits and sleep phrases above.

## 5. Build

The module builds the static library `xWalkVoiceActiveCarGpt` with alias `xWalk::VoiceActiveCarGpt` (C++17,
strict GNU/Clang warnings). It links `xWalkVoiceActiveCar` publicly and `xWalkTrace` privately, and adds the
`xWalkVoiceActiveCar` subdirectory with its host test disabled when that target is absent. From the repository
root:

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver -B xWalk-rpi5-hw/xWalkDriver/build-host -DXWALK_AGENT_BUILD_HOST=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/build-host --target xWalkVoiceActiveCarGptTest
```

## 6. Configuration

| CMake option | Default | Meaning |
| --- | --- | --- |
| `XWALK_VOICE_ACTIVE_CAR_GPT_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkVoiceActiveCarGptTest` |

Deployment values use the `voice_active_car_gpt_*` keys in
`features.conf`; the
optional Gemini
provider is described by
`gemini.conf`.

## 7. Testing

`xWalkVoiceActiveCarGptHostTest` (label `host`) checks the Jarvis instructions, allowed actions, welcome
message, configuration values, wake-phrase matching, sleep phrases, and every published constant.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-host --output-on-failure -R xWalkVoiceActiveCarGptHostTest
```

The module defines no hardware test. The voice group hardware-profile test is described in
[xWalkVoice](../xWalkVoice.md); list it with `ctest -N -L hardware` and run it only with explicit approval and
a confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- [xWalkVoiceActiveCar](../xWalkVoiceActiveCar/xWalkVoiceActiveCar.md) - shared coordinator and types.
- [xWalkSelfDrive](../../xWalkVehicle/xWalkSelfDrive/xWalkSelfDrive.md) - action allowlist and worker.
- [xWalkWebSearch](../../../xWalkHal/interface/xWalkWebSearch/xWalkWebSearch.md) - bounded SearXNG client.
- [xWalkGPT](../../../xWalkHal/layer1/xWalkGPT/xWalkGPT.md) - Vosk recognition and speech backends.
- `xWalkTrace` - private trace support.

## 9. Safety and constraints

- Only locally allowlisted action names execute; model text cannot add capabilities.
- Conversational answers and retrieval-assisted rounds emit only `stop`.
- Jarvis never captures images; the model always receives an empty image path.
- Session shutdown, cancellation, and terminal errors stop vehicle output.
- Credentials are read from the environment only when an optional remote provider is selected.

## 10. Related notes

- [xWalkVoice](../xWalkVoice.md) - voice Agent group.
- [xWalkVoiceActiveCar](../xWalkVoiceActiveCar/xWalkVoiceActiveCar.md) - Rolly profile and coordinator.
- [xWalkGptCar](../xWalkGptCar/xWalkGptCar.md) - GPT-car voice Agent.
- xWalkBoot - Controller composition.

> Personalized messages show `[operator]` in place of the deployment-specific name.

---

[Previous page](../xWalkVoiceActiveCar/config/xWalkVoiceActiveCar%20Configuration.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkVoiceControlledCar/xWalkVoiceControlledCar.md)
