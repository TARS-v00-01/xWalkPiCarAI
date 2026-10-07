<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkGPT

**2. xWalk hardware &middot; Module 90**

<!-- xwalk-page-header:end -->

# xWalkGPT

C++17 embedded-oriented speech interface containing the Robot HAT speech-to-text and text-to-speech
coordinators, the shared-ALSA speech adapters, and optional offline Vosk, Espeak, Piper, and Pico2Wave
providers.

## 1. Overview

The module combines the former `xWalkSpeechToText` and `xWalkTextToSpeech` libraries while retaining one
focused class per header and source file:

- `XWalkSpeechToText` provides readiness, bounded microphone recognition, audio-file transcription, and
  cancellation through an injected backend.
- `XWalkTextToSpeech` activates Robot HAT speaker output through `XWalkBoardControl` and forwards speech
  text through an injected synthesis backend.
- `XWalkSpeechToTextAlsa` captures microphone PCM through ALSA and streams it to one injected recognizer.
- `XWalkTextToSpeechAlsa` writes provider PCM through the shared `XWalkAudioAlsa` owner.
- `XWalkSpeechRecognizerVosk` loads the Vosk C API and one offline model at runtime without requiring vendor
  headers during compilation.
- `XWalkTextToSpeechEspeak` runs Espeak without a shell and converts its WAV output into PCM for the shared
  ALSA playback adapter.
- `XWalkTextToSpeechPiper` runs Piper and WAV playback without a shell using a deployment-selected model.
- `XWalkTextToSpeechPico2Wave` runs language-selected Pico2Wave synthesis and WAV playback without a shell.

Core behavior, simulation, and host tests use the unique trace IDs `RPI.357` through `RPI.369`. The
repository validator rejects repeated numeric IDs within `RPI`.

### Composition and ownership

Create board control and speech backends in `main()`. Pass board control by reference and backend state
through documented non-owning context pointers. The application must keep every referenced object alive for
the complete coordinator lifetime. Destroying `XWalkTextToSpeech` does not disable shared speaker power.

`XWalkSpeechToTextAlsa` owns one ALSA capture handle and one streaming recognition session for each bounded
listen request. It captures 16 kHz mono signed-16 PCM in reads of no more than 1,024 frames and feeds every
completed period immediately to the selected recognizer. Vosk endpoint acceptance after speech and trailing
silence ends the listen and returns the accepted result. The deployed Vosk 0.3.45 C API has no
endpoint-timing setter, so the adapter also provides a bounded fallback. The fallback arms only after Vosk
returns a non-empty partial transcript, then applies configured minimum-speech, trailing-low-level, and
maximum-utterance periods. Quiet initial input cannot arm it. The requested timeout remains the hard upper
bound and finalizes any partial utterance. PCM is not accumulated for the duration of a streaming listen.

Cancellation is observed between bounded ALSA reads and by the Vosk provider. Scope-bound guards close the
capture handle and release the recognition session on normal completion, cancellation, and thrown error
paths, without exception interception. The recognizer still exposes compatible whole-buffer PCM and
audio-file operations for callers outside the streaming microphone path. It owns its model, process or HTTP
transport, credentials, language policy, and provider-specific conversion. The recognition context remains
non-owning and must outlive the adapter. The application selects one local or remote recognizer and supplies
all recognition operations.

`XWalkTextToSpeechAlsa` observes one caller-owned `XWalkAudioAlsa`. It forwards text to one injected local
or remote synthesis provider, validates at most 16 MiB of interleaved signed-16 PCM, and writes no more than
1,024 frames per shared ALSA operation. Empty provider PCM completes without opening an audio stream. The
provider owns its model, voice, credentials, process or HTTP transport, and decoding policy. Construct the
shared audio owner before the adapter and destroy the adapter first.

The offline Raspberry Pi graphs are:

```text
Vosk model → XWalkSpeechRecognizerVosk → XWalkSpeechToTextAlsa
           → XWalkSpeechToText → XWalkVoiceControlledCar

Espeak → XWalkTextToSpeechEspeak → XWalkTextToSpeechAlsa
       → XWalkTextToSpeech → XWalkVoicePromptCar
```

### Piper cancellation and model selection

`XWalkTextToSpeechPiper::setCancellation()` borrows an owner-held atomic latch while idle. Synthesis and
playback run in separately owned process groups. The provider polls its direct child every 10 ms, sends TERM
on cancellation, allows 100 ms of grace, then sends KILL and reaps the direct child before returning
interruption. It never searches by process name or signals unrelated processes. Playback stderr is privately
captured with 4096 bytes of storage and bounded nonblocking reads; raw child output is not forwarded into
diagnostics.

Playback configured as `aplay` (including an absolute path) may handle delivered TERM by exiting with status
1. That outcome counts as `XWalkOperationCancelled` when diagnostics are benign or contain the supported,
ordered C-locale TERM acknowledgement followed by an interrupted PCM write. Empty output, a TERM
acknowledgement alone, and an ordinary `Playing WAVE` banner are permitted. Synthesis and other playback
programs retain status-one failure behavior. Failures observed before TERM and other nonzero exits remain
fixed-context provider failures. During cancellation, pre-existing errors, additional diagnostics, incomplete
reports, and capture overflow also retain failure. TERM/KILL termination retains cancellation semantics
unless captured playback diagnostics indicate a failure. The private WAV is removed on every exit path, and
cancellation prevents starting playback.

Exit status and external text do not prove causality: an unrelated failure with exactly the same outcome
after TERM is indistinguishable. Localized or changed error diagnostics still fail closed; use a C-locale
runtime for the supported interrupted-write report. Normal completion still succeeds; a clean TERM handler
exiting zero also reports cancellation. Microphone cancellation latency is a separate limitation and is
unchanged. Normal speech retains the existing `piper -m MODEL -f WAV -- TEXT` invocation contract.

The selected model must be an absolute `.onnx` path with a readable, nonempty `.onnx.json` companion. Use
the deployment tool's `configure-rpi-runtime.sh --validate-model-only` before live requests; it validates the
effective operator selection without invoking synthesis. Generation and HOST builds do not require assets.
No fallback voice is silently selected when an asset is missing.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT` —
source directory

## 3. Directory layout

```text
xWalkGPT/
├── CMakeLists.txt                  Libraries, provider options, host and hardware tests
├── include/                        Public coordinator contracts
│   ├── xHal_Rpi5CarSpeechToText.h        XWalkSpeechToText coordinator
│   ├── xHal_Rpi5CarSpeechToTextTypes.h   Recognition callback table
│   ├── xHal_Rpi5CarTextToSpeech.h        XWalkTextToSpeech coordinator
│   └── xHal_Rpi5CarTextToSpeechTypes.h   Synthesis callback type
├── src/                            Coordinator behavior and lifecycle
├── hardware/
│   ├── include/                    ALSA adapters, guards, and offline provider contracts
│   ├── src/                        ALSA capture/playback, Vosk, Espeak, Piper, Pico2Wave
│   └── test/
│       ├── include/                TTS ALSA test types
│       └── src/                    ALSA adapter host tests and the STT hardware test
├── simulation/                     Device-free executable and trace catalogue generator
└── test/
    ├── include/                    xHal_Rpi5CarGptTestSupport.h
    ├── src/                        STT, TTS, Piper cancellation tests and shared support
    └── hardware/                   TTS playback hardware test and its types
```

## 4. Child modules

- [xWalkGPT Simulation](simulation/xWalkGPT%20Simulation.md) — device-free STT and TTS coordination
  executable with persistent trace selection.

## 5. Public interface

Headers are in `include`.

| Header | Contract |
|---|---|
| `xHal_Rpi5CarSpeechToText.h` | `isReady()`, `listen(timeoutMs)`, `transcribeFile()`, `stop()` |
| `xHal_Rpi5CarSpeechToTextTypes.h` | `XWalkSpeechToTextCallbacks` ready, listen, file, and stop entries |
| `xHal_Rpi5CarTextToSpeech.h` | Board-control speaker activation and `speak(text)` |
| `xHal_Rpi5CarTextToSpeechTypes.h` | `texttospeechspeakcallback` synthesis entry |

`listen()` defaults to `XHAL_RPI5CAR_SPEECH_TO_TEXT_DEFAULT_TIMEOUT_MS` (30,000 ms) and rejects zero or values
above `XHAL_RPI5CAR_SPEECH_TO_TEXT_MAXIMUM_TIMEOUT_MS` (300,000 ms); both are defined in the shared common
header. Coordinators are non-copyable and non-movable. Hardware adapter and provider contracts live under
`hardware/include`.

## 6. Build

| CMake option | Default | Effect |
|---|---:|---|
| `XWALK_GPT_BUILD_HOST_TESTS` | `OFF` | Host tests; also builds the STT/TTS ALSA adapters and the Piper provider |
| `XWALK_GPT_BUILD_HARDWARE_TESTS` | `OFF` | Hardware-labelled STT and TTS executables |
| `XWALK_GPT_BUILD_STT_ALSA_BACKEND` | `OFF` | `xWalkSpeechToTextAlsa` |
| `XWALK_GPT_BUILD_TTS_ALSA_BACKEND` | `OFF` | `xWalkTextToSpeechAlsa` over `xWalkAudioAlsa` |
| `XWALK_GPT_BUILD_VOSK_PROVIDER` | `OFF` | `xWalkSpeechRecognizerVosk` (implies the STT ALSA adapter) |
| `XWALK_GPT_BUILD_ESPEAK_PROVIDER` | `OFF` | `xWalkTextToSpeechEspeak` (implies the TTS ALSA adapter) |
| `XWALK_GPT_BUILD_PIPER_PROVIDER` | `OFF` | `xWalkTextToSpeechPiper`; also built for `XWALK_HAL_BUILD_HOST` |
| `XWALK_GPT_BUILD_PICO2WAVE_PROVIDER` | `OFF` | `xWalkTextToSpeechPico2Wave` |

The core `xWalkGPT` static library links `xWalkBoardControl` and `xWalkLibraryCommon` publicly and
`xWalkTrace` privately. ALSA adapters and offline providers require Linux; configuration fails otherwise.

## 7. Configuration

The Vosk provider resolves a caller-supplied shared-library path at runtime and therefore requires a
target-compatible Vosk runtime plus a model directory. The aggregate repository provides separate ARM64 and
x86-64 Vosk 0.3.45 runtimes under
`xWalkLibrary/aarch64` and
`xWalkLibrary/x86_64`, and one shared small US
English 0.15 model under
`xWalkLibrary/common/models`;
deployments may override both paths. The Espeak provider requires the `espeak-ng` executable, and the
Pico2Wave provider requires `pico2wave` from `libttspico-utils` plus a WAV playback executable. None of these
providers uses a shell.

Normal traces report session start, endpoint source, hard-timeout finalization, empty recognition, and
transcript length. Transcript contents remain private unless `voice_vosk_trace_transcript = true` is
explicitly selected for local diagnosis. Do not enable content tracing in shared or production environments.

The host simulation and core tests use a generated XML catalogue produced by
`simulation/config/xHal_Rpi5CarGptTraceConfig.py`.
For example, `--trace RPI.363.enable` saves the enabled state, and a later no-flag run loads it
automatically. Enabled records are written to the terminal and log. Speech text and transcripts are
excluded by default; captured PCM and credentials are always excluded.

## 8. Testing

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/build-host -DXWALK_GPT_BUILD_HOST_TESTS=ON
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/build-host --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/build-host --output-on-failure
```

| CTest name | Label | Scope |
|---|---|---|
| `xWalkSpeechToTextHostTest` | `host` | Coordinator, simulation arguments, and trace persistence |
| `xWalkTextToSpeechHostTest` | `host` | Speaker activation and synthesis forwarding |
| `xWalkSpeechToTextAlsaHostTest` | `host` | Injected ALSA capture and streaming recognition |
| `xWalkTextToSpeechAlsaHostTest` | `host` | Injected shared-ALSA playback and PCM validation |
| `xWalkPiperCancellationHostTest` | `host` | Piper process cancellation, reaping, and reuse (20 s timeout) |

The host tests use deterministic in-memory backends. They perform no microphone, model, network, or physical
speaker operation; the Piper cancellation fixtures use local child processes only. Reusable core callback
state and functions live in `xwalk::hal::test::gpt`, outside the scenario test sources. Piper fixtures
require completion within two seconds for ordinary cancellable processes and verify unrelated process
survival, reaping, failure during cancellation, and reuse. Kernel uninterruptible I/O and descendants that
deliberately escape their process group cannot be given that bound. Actual Piper/ALSA latency still needs Pi
verification.

Compile the target tests and list them without running:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/build-rpi -DXWALK_GPT_BUILD_HARDWARE_TESTS=ON
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/build-rpi --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/build-rpi -N -L hardware
```

The hardware-labelled tests are `xWalkSpeechToTextMicrophoneHardwareTest` and
`xWalkTextToSpeechPlaybackHardwareTest`. CTest registers both without arguments, so listing remains safe; do
not execute either through ordinary verification. Run them only with explicit approval on a confirmed safe
Raspberry Pi and Robot HAT setup.

The speech-to-text hardware executable captures only 100 milliseconds and requires an explicit ALSA capture
device as its sole argument. It sends PCM to a deterministic recognition sink and does not enable speakers or
actuators. Use `arecord -L` to discover device names:

```bash
xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/build-rpi/xWalkSpeechToTextHardwareTest <alsa-capture-device>
```

The text-to-speech hardware executable requires the PCM device, mixer device, mixer element, and a
deployment-owned raw 16 kHz mono signed-16 little-endian fixture containing the fixed phrase documented by
the executable. It applies 15 percent mixer volume and performs bounded playback. Use `aplay -L` and `amixer`
to verify names before execution:

```bash
xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/build-rpi/xWalkTextToSpeechHardwareTest <pcm> <mixer> <element> <fixture.raw>
```

## 9. Dependencies

- `xWalkBoardControl` for speaker activation and priming.
- `xWalkAudio` (`xWalkAudioAlsa`) for TTS playback; added automatically when a TTS ALSA target is needed.
- `xWalkLibraryCommon` and `xWalkTrace`; `XWalkDependencies.cmake` from `xWalkLibrary`.
- ALSA development files for the adapters; `${CMAKE_DL_LIBS}` for the runtime-loaded Vosk provider.
- Python 3 for trace catalogue generation in host tests.

## 10. Safety and constraints

- Do not include captured PCM, transcripts, credentials, or provider requests in normal diagnostics.
- Confirm the correct Robot HAT, speaker-power state, fixture content, and safe acoustic environment before
  any approved playback test.
- Neither retained Vosk library supports 32-bit Raspberry Pi OS.
- Every non-owning context, audio owner, and recognizer must outlive the objects that observe it.

## 11. Related notes

- [xWalkHal Layer1](../xWalkHal%20Layer1.md)
- [xWalkHal Layer1 Tests](../test/xWalkHal%20Layer1%20Tests.md)
- [xWalkHal](../../xWalkHal.md)
- [xWalkBoardControl](../xWalkBoardControl/xWalkBoardControl.md)
- [xWalkVoiceAssistant](../xWalkVoiceAssistant/xWalkVoiceAssistant.md)
- [xWalkAudio](../../interface/xWalkAudio/xWalkAudio.md)
- [xWalkLibrary](../../../xWalkLibrary/xWalkLibrary.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkBoardControl/simulation/xWalkBoardControl%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkGPT%20Simulation.md)
