<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkVoiceAssistant

**2. xWalk hardware &middot; Module 99**

<!-- xwalk-page-header:end -->

# xWalkVoiceAssistant

`xWalkVoiceAssistant` provides synchronous, backend-neutral speech and model orchestration. `XWalkVoiceAssistant`
coordinates one listen, model, and speech round over caller-owned speech-to-text, language-model, and
text-to-speech coordinators.

## 1. Overview

The application creates `XWalkSpeechToText`, `XWalkLanguageModel`, and `XWalkTextToSpeech` in `main()` and passes
references to the coordinator. The assistant stores non-owning pointers and owns no microphone, model, network,
camera, speaker, trigger, thread, or operating-system resource.

Core behavior, simulation, and host tests use unique trace IDs `RPI.370` through `RPI.382`. The repository
validator rejects repeated numeric IDs within `RPI`. Trace messages report only lifecycle state and text lengths,
never speech text, prompts, model responses, captured audio, fixtures, or credentials.

One round performs these operations:

1. Check speech-backend readiness and listen until its recognizer reports an utterance endpoint or the
   configured hard timeout is reached.
2. Preserve silence as an empty result without prompting or speaking.
3. Submit non-empty recognized or caller-supplied text to the language model.
4. Optionally parse the final response and speak a non-empty parsed response.
5. Notify synchronous lifecycle callbacks without retaining their text views.

Wake-word detection, keyboard polling, image capture, continuous loops, streaming tokens, and scheduling remain
application or backend responsibilities. Calls require external serialization and may block in injected
backends. The completed Vosk/ALSA backend feeds microphone periods incrementally and normally returns after
speech followed by recognizer-detected trailing silence; it does not claim real-time latency. The configured
listen duration remains a safety upper bound for initial silence or speech continuing without an endpoint.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkVoiceAssistant`
(source directory)

## 3. Directory layout

```text
xWalkVoiceAssistant/
├── CMakeLists.txt                                  Library, host-test, and hardware-test targets
├── include/
│   ├── xHal_Rpi5CarVoiceAssistant.h                XWalkVoiceAssistant API
│   └── xHal_Rpi5CarVoiceAssistantTypes.h           Configuration and lifecycle callback types
├── src/
│   ├── xHal_Rpi5CarVoiceAssistant.cpp              Listen, think, say, and round orchestration
│   └── xHal_Rpi5CarVoiceAssistantLifecycle.cpp     Construction, start, and stop
├── hardware/test/                                  Completed-backend composition host test and support
├── simulation/                                     Standalone device-free simulation
│   ├── config/xHal_Rpi5CarVoiceAssistantTraceConfig.py
│   ├── include/
│   └── src/
└── test/
    ├── include/xHal_Rpi5CarVoiceAssistantTestSupport.h   xwalk::hal::test::voiceassistant support
    ├── src/                                        Coordinator host test and support implementation
    └── hardware/                                   Opt-in hardware composition test and its types
```

## 4. Child modules

| Note | Description |
|---|---|
| [xWalkVoiceAssistant Simulation](simulation/xWalkVoiceAssistant%20Simulation.md) | Device-free simulation |

## 5. Public interface

The public headers are in the module
`include` directory.

- `XWalkVoiceAssistant` provides `start()`, `stop()`, `isRunning()`, `listen()`, `think()`, `say()`,
  `processText()`, and `runRound()`. `think()`, `processText()`, and `runRound()` accept an optional image path
  for the language model.
- `XWalkVoiceAssistantConfiguration` holds the model `instructions` and an optional `welcome` text spoken on
  start.
- `XWalkVoiceAssistantCallbacks` groups optional synchronous hooks: `onStart`, `beforeListen`, `afterListen`,
  `onHeard`, `beforeThink`, `afterThink`, `parseResponse`, `beforeSay`, `afterSay`, `onRoundComplete`, and
  `onStop`. A null parse callback preserves the unmodified final model response.

The completed-backend application composition order is:

1. Create the shared `XWalkAudioAlsa` owner.
2. Create `XWalkSpeechToTextAlsa` with an application-selected recognizer, then create `XWalkSpeechToText` from
   its callbacks.
3. Create `XWalkLanguageModelOllama`, then create `XWalkLanguageModel` from its callbacks.
4. Create `XWalkTextToSpeechAlsa` with an application-selected synthesizer, then create `XWalkTextToSpeech` with
   caller-owned board control.
5. Create `XWalkVoiceAssistant` last so it is destroyed before every dependency.

## 6. Build

| Option | Default | Effect |
|---|---:|---|
| `XWALK_VOICE_ASSISTANT_BUILD_HOST_TESTS` | `OFF` | Builds host tests and the GPT and Language Model host tests |
| `XWALK_VOICE_ASSISTANT_BUILD_HARDWARE_TESTS` | `OFF` | Builds the target composition and dependent tests |

A standalone build adds `xWalkLibrary/common`, `xWalk-rpi5-trace`, `xWalkGPT`, and `xWalkLanguageModel` when
their targets are not already defined.

## 7. Configuration

The host test and standalone simulation use a generated XML trace catalogue produced by
`simulation/config/xHal_Rpi5CarVoiceAssistantTraceConfig.py`. A selector such as `--trace RPI.379.enable` is saved
atomically, and the next run without a selector loads it automatically. Enabled trace records are written to both
terminal and log.

## 8. Testing

Run from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkVoiceAssistant -B build/xWalkVoiceAssistant-host -DXWALK_VOICE_ASSISTANT_BUILD_HOST_TESTS=ON
cmake --build build/xWalkVoiceAssistant-host --parallel
ctest --test-dir build/xWalkVoiceAssistant-host --output-on-failure
```

| CTest name | Executable | Labels |
|---|---|---|
| `xWalkVoiceAssistantHostTest` | `xWalkVoiceAssistantTest` | `host` |
| `xWalkVoiceAssistantBackendsHostTest` | `xWalkVoiceAssistantBackendsTest` | `host` |

The suite includes both neutral coordinator coverage and a completed-backend composition test. Every backend
operation is deterministic and in memory. The full-stack host test follows the composition order above with
injected ALSA operations, a fake recognizer, fake Ollama transport, and fake synthesis. It verifies a complete
capture, recognition, model, synthesis, and playback round without opening a device, contacting a model, or
writing a file. Reusable callback state and functions live in `xwalk::hal::test::voiceassistant`, outside the
scenario source. In a workspace build the coordinator scenarios run in `xGoogleTest` as
`TEST_SUITE_XWALK_VOICE_ASSISTANT`.

Target compile check, which only lists hardware-labelled tests and does not execute them:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkVoiceAssistant -B build/xWalkVoiceAssistant-rpi -DXWALK_VOICE_ASSISTANT_BUILD_HARDWARE_TESTS=ON
cmake --build build/xWalkVoiceAssistant-rpi --parallel
ctest --test-dir build/xWalkVoiceAssistant-rpi -N -L hardware
```

The hardware-labelled CTest entry is `xWalkVoiceAssistantBackendsHardwareTest`, which runs
`xWalkVoiceAssistantHardwareTest`. The executable requires eight arguments: an explicit ALSA capture device, PCM
device, mixer device, mixer element, Ollama endpoint, model, approved prompt, and raw 16 kHz mono signed-16
little-endian response fixture. It captures 100 milliseconds, validates that microphone PCM was received, maps it
to the approved prompt, performs one non-streaming Ollama request, and plays the fixture for the non-empty
response at 15 percent volume. It prints no microphone, prompt, model-response, fixture, or credential content.
The CTest registration passes no arguments, so the registered entry cannot perform the round; a manual
invocation is required.

This smoke executable deliberately uses non-physical board-control seams and does not claim GPIO or I2C. Confirm
speaker power separately through approved deployment setup. Only after explicit approval of microphone privacy,
network policy, endpoint, model, prompt, speaker power, devices, acoustic volume, and fixture content, on a
confirmed safe Raspberry Pi and Robot HAT setup, the manual form is:

```bash
cd build/xWalkVoiceAssistant-rpi && ./xWalkVoiceAssistantHardwareTest <capture> <pcm> <mixer> <element> <endpoint> <model> <prompt> <fixture>
```

Real recognition and synthesis provider operations remain deployment-selected as defined by `xWalkGPT`; the
smoke test validates their composition boundaries.

## 9. Dependencies

- Public: `xWalkGPT`, `xWalkLanguageModel`, and `xWalkLibraryCommon`.
- Private: `xWalkTrace`.
- Completed-backend and hardware tests: `xWalkSpeechToTextAlsa`, `xWalkTextToSpeechAlsa`, and
  `xWalkLanguageModelOllama`.

## 10. Safety and constraints

- Every injected coordinator must outlive the assistant; create the assistant last.
- Calls require external serialization and may block in injected backends.
- Trace output never contains speech text, prompts, responses, audio, fixtures, or credentials.
- The hardware test captures microphone audio, contacts a model endpoint, and plays audio; it is opt-in.

## 11. Related notes

- [xWalkHal Layer1](../xWalkHal%20Layer1.md)
- [xWalkHal Layer1 Tests](../test/xWalkHal%20Layer1%20Tests.md)
- [xWalkGPT](../xWalkGPT/xWalkGPT.md)
- [xWalkLanguageModel](../../interface/xWalkLanguageModel/xWalkLanguageModel.md)
- [xWalkAudio](../../interface/xWalkAudio/xWalkAudio.md)
- [xWalkHal](../../xWalkHal.md)

---

[Previous page](../xWalkSpeaker/simulation/xWalkSpeaker%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkVoiceAssistant%20Simulation.md)
