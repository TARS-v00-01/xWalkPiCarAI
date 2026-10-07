<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkSpeaker

**2. xWalk hardware &middot; Module 97**

<!-- xwalk-page-header:end -->

# xWalkSpeaker

C++17 bounded asynchronous speaker playback for the xWalk Firmware HAL, with an optional adapter over the
shared `XWalkAudioAlsa` owner.

## 1. Overview

The module enables and disables speaker output, validates supported audio files, starts bounded background
playback tasks, reports progress, and supports pause, resume, stop, and automatic cleanup.

The optional `XWalkSpeakerAlsa` adapter connects every callback to the shared `XWalkAudioAlsa` owner. It
provides bounded 16-bit PCM RIFF/WAVE decoding and an injected decoder seam for FLAC, OGG, MP3, M4A, AAC, or
WMA codec libraries.

### Ported behavior

- Speaker output is enabled during construction and disabled during destruction.
- WAV, FLAC, and OGG files select the native SoundFile decoder family.
- MP3, M4A, AAC, and WMA files select the native compressed-audio decoder family.
- Decoded samples use interleaved normalized floating-point values.
- Each `play()` call returns a backend-generated unique task identifier.
- Progress includes frame position, total frames, ratio, elapsed and total seconds, and playing state.
- Pause, resume, stop, active-task listing, normal completion, and cleanup are supported.
- Worker backend operations must not throw; a violation terminates the process.

The core library does not link `pyaudio`, `soundfile`, `librosa`, or NumPy. A platform implementation
supplies equivalent decode and stream callbacks.

### Composition and ownership

The application creates its platform decoder and audio-output backend, then passes a non-owning context and
complete callback table to `XWalkSpeaker`.

```cpp
AudioBackend backend;
const XWalkHal::XWalkSpeakerCallbacks callbacks = makeSpeakerCallbacks();
XWalkHal::XWalkSpeaker speaker(&backend, callbacks);
const XWalkHal::string taskId = speaker.play("notification.wav");
```

The backend context must outlive the controller and every playback worker. The backend owns each opaque
stream returned by `openStream`; `XWalkSpeaker` closes the stream through `closeStream` but never deletes or
casts the handle.

For Raspberry Pi composition, create the shared owner before its adapter and controller:

```cpp
XWalkHal::XWalkAudioAlsa audio(pcmDevice, mixerDevice, mixerElement);
XWalkHal::XWalkSpeakerAlsa adapter(audio, playbackVolumePercent);
XWalkHal::XWalkSpeaker speaker(&adapter, adapter.callbacks());
```

The audio owner must outlive the adapter, and the adapter must outlive the Speaker controller and all its
workers. Disabling Speaker does not close or mute the shared owner because Music or speech consumers may
still use it.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker` —
source directory

## 3. Directory layout

```text
xWalkSpeaker/
├── CMakeLists.txt                        Libraries, options, host and hardware tests
├── include/
│   ├── xHal_Rpi5CarSpeaker.h             Public lifecycle, playback, progress, and task-control contract
│   └── xHal_Rpi5CarSpeakerTypes.h        Audio, progress, callback, and bounded task types
├── src/
│   ├── xHal_Rpi5CarSpeakerLifecycle.cpp  Backend validation and speaker-output lifecycle
│   ├── xHal_Rpi5CarSpeakerPlayback.cpp   File validation, format selection, decoding, and task creation
│   ├── xHal_Rpi5CarSpeakerTasks.cpp      Progress, pause, resume, stop, listing, joining, and cleanup
│   └── xHal_Rpi5CarSpeakerWorker.cpp     Bounded frame writes and stream cleanup
├── hardware/
│   ├── include/
│   │   ├── xHal_Rpi5CarSpeakerAlsa.h             Shared-audio dependency, callbacks, limits, lifetime
│   │   └── xHal_Rpi5CarSpeakerAlsaTypes.h        Optional bounded decoder operation seam
│   ├── src/
│   │   ├── xHal_Rpi5CarSpeakerAlsaCallbacks.cpp  Float32 conversion, streams, volume, task identifiers
│   │   ├── xHal_Rpi5CarSpeakerAlsaDecode.cpp     Bounded PCM RIFF/WAVE decoding and sample validation
│   │   └── xHal_Rpi5CarSpeakerAlsaLifecycle.cpp  Dependency binding and callback publication
│   └── test/
│       ├── include/xHal_Rpi5CarSpeakerAlsaTestTypes.h
│       └── src/
│           ├── xHal_Rpi5CarSpeakerAlsaTest.cpp          Device-free decoder, conversion, failure tests
│           └── xHal_Rpi5CarSpeakerAlsaHardwareTest.cpp  Opt-in short silent WAVE playback test
├── simulation/                           Silent in-memory decoder/stream backend and trace executable
└── test/
    ├── include/xHal_Rpi5CarSpeakerTestSupport.h  Named decoder and stream callbacks for host tests
    └── src/
        ├── xHal_Rpi5CarSpeakerTest.cpp           In-memory output, stream, task, and validation coverage
        └── xHal_Rpi5CarSpeakerTestSupport.cpp
```

## 4. Child modules

- [xWalkSpeaker Simulation](simulation/xWalkSpeaker%20Simulation.md) — silent executable that composes the
  real task controller over an in-memory decoder and stream backend.

## 5. Public interface

`xHal_Rpi5CarSpeaker.h` in `include`
declares `XWalkSpeaker(context, callbacks)`:

| Operation | Behavior |
|---|---|
| `enableSpeaker`, `disableSpeaker`, `isSpeakerEnabled` | Speaker-output control |
| `play(filePath)` | Validates and decodes a file, starts a task, and returns its identifier |
| `getProgress(taskId)` | Returns `XWalkSpeakerProgress` for one task |
| `pause`, `resume`, `stop` | Task control; `stop` reports whether a task was found |
| `listTasks()` | Active task identifiers |

Task storage is deliberately bounded to eight concurrent tasks (`XHAL_RPI5CAR_SPEAKER_MAXIMUM_TASK_COUNT`).
Playback writes contain at most 1,024 frames, and paused workers inspect their state every 10 milliseconds.
These limits prevent unbounded task metadata growth and provide predictable control latency between backend
writes. The limits are defined in the shared common header.

Mutating operations must be called from one controlling execution context. The internal mutex coordinates
that context with playback workers. Backend write operations must return in bounded time so stop and
destruction can join workers safely.

The built-in ALSA adapter checks the file size before reading and accepts at most 16 MiB of input and
2,000,000 decoded interleaved samples per task. It decodes non-empty 16-bit integer PCM WAVE data with one
through eight channels. Other formats require an explicitly selected bounded decoder callback; optional codec
libraries remain outside `xWalkSpeaker` and `xWalkAudio`.

## 6. Build

| CMake option | Default | Effect |
|---|---:|---|
| `XWALK_SPEAKER_BUILD_HOST_TESTS` | `OFF` | Host tests; also builds the ALSA adapter |
| `XWALK_SPEAKER_BUILD_HARDWARE_TESTS` | `OFF` | Hardware-labelled low-volume playback test |
| `XWALK_SPEAKER_BUILD_ALSA_BACKEND` | `OFF` | `xWalkSpeakerAlsa` over `xWalkAudioAlsa` |

The core `xWalkSpeaker` static library links `xWalkLibraryCommon` publicly and `xWalkTrace` privately. The
ALSA adapter requires Linux and ALSA development headers.

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker/build-rpi -DXWALK_SPEAKER_BUILD_HARDWARE_TESTS=ON
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker/build-rpi --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker/build-rpi -N -L hardware
```

## 7. Configuration

Use `aplay -l`, `aplay -L`, and `amixer scontrols` to confirm the configured devices and mixer element.

The module uses unique `RPI` identifiers (`RPI.308` through `RPI.320`) for successful controller-thread task
operations. Enabled messages are written to the terminal and configured log file. A selector such as
`RPI.316.enable` updates the generated XML catalogue produced by
`simulation/config/xHal_Rpi5CarSpeakerTraceConfig.py`; later runs load that state without another selector.
The worker, cleanup, output-disable, worker-callback, and destructor paths contain no trace operations.

## 8. Testing

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker/build-host -DXWALK_SPEAKER_BUILD_HOST_TESTS=ON
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker/build-host --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker/build-host --output-on-failure
```

| CTest name | Labels | Scope |
|---|---|---|
| `xWalkSpeakerHostTest` | `host` | Concurrency suite with build-local fixtures (30 s timeout) |
| `xWalkSpeakerFailureHostTest` | `host;failure-isolation` | Process-isolated exception and worker-termination |
| `xWalkSpeakerAlsaHostTest` | `host` | Injected decoder and ALSA operations with WAV, OGG, MP3 fixtures |
| `xWalkSpeakerAlsaLowVolumeHardwareTest` | `hardware` | Opt-in short silent WAVE playback |

The host suites use module-local fixtures plus injected decoder and ALSA operations. They do not access an
audio device. The concurrency suite remains enabled under ThreadSanitizer. `xWalkSpeakerFailureHostTest` is
registered only when `XWALK_ENABLE_THREAD_SANITIZER` is off, because forking a process with active
instrumented worker threads can deadlock the ThreadSanitizer runtime. Both speaker tests have a 30-second
CTest timeout.

The hardware test generates a 256-frame silent WAVE file at `/tmp/xwalk-speaker-alsa-hardware-test.wav`,
applies five-percent mixer volume, plays it, and removes the fixture. Merely list it during normal
verification. Run it only with explicit approval after confirming the correct Raspberry Pi and Robot HAT
audio setup. Optional arguments are PCM device, mixer device, and mixer element names, in that order.

## 9. Dependencies

- `xWalkLibraryCommon` and `xWalkTrace`.
- `xWalkAudio` (`xWalkAudioAlsa`) and ALSA development files for the adapter.
- Python 3 for trace catalogue generation in host tests.

## 10. Safety and constraints

- The backend context must outlive the controller and every playback worker.
- Backend write operations must be bounded in time; worker backend operations must not throw.
- Disabling Speaker never closes or mutes the shared audio owner.
- Hardware playback is silent, uses five-percent mixer volume, and remains opt-in.

## 11. Related notes

- [xWalkHal Layer1](../xWalkHal%20Layer1.md)
- [xWalkHal Layer1 Tests](../test/xWalkHal%20Layer1%20Tests.md)
- [xWalkHal](../../xWalkHal.md)
- [xWalkMusic](../xWalkMusic/xWalkMusic.md)
- [xWalkAudio](../../interface/xWalkAudio/xWalkAudio.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkRobot/simulation/xWalkRobot%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkSpeaker%20Simulation.md)
