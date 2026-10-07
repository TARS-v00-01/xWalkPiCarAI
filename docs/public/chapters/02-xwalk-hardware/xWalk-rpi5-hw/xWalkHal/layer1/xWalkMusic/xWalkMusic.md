<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkMusic

**2. xWalk hardware &middot; Module 93**

<!-- xwalk-page-header:end -->

# xWalkMusic

C++17 music timing, tone generation, and audio-output coordination for the xWalk Firmware HAL, with an
optional shared-ALSA adapter and optional libsndfile decoder.

## 1. Overview

The module provides music timing and key state, MIDI-compatible note frequencies, sound-effect and
streamed-music control, and signed 16-bit mono PCM tone generation. Platform audio is supplied through
caller-owned callbacks, so the core library does not depend on `pygame`, `pyaudio`, or a Linux audio API.

The optional `XWalkMusicAlsa` adapter implements every callback through the shared `XWalkAudioAlsa` owner.
Its built-in decoder accepts uncompressed 16-bit PCM RIFF/WAVE files with one through eight channels. The
optional `XWalkMusicSndFileDecoder` uses libsndfile to add native MP3 and other libsndfile-supported formats
while preserving the same PCM contract.

### Ported behavior

- 4/4 default time signature and 120 quarter-note beats per minute
- Named major-key macros, integers, and repeated `#` or `b` keys from minus seven through seven
- Named notes from `A0` through `C8`, including sharp spellings
- Equal-temperament conversion from the A4 reference of 440 Hertz at MIDI note 69
- Synchronous and background sound-effect operations with optional volume
- Streamed-music play, volume, stop, pause, resume, and unpause operations
- Sound duration rounded to two decimal places
- Signed 16-bit mono PCM tone data at 44,100 Hertz

Tone generation halves the requested duration, generates that many sine frames, and then appends
`frameCount % 44,100` silent frames. This observable byte-count and silence behavior is intentional.

Inputs that could otherwise cause undefined, unbounded, or ambiguous behavior are validated. Time-signature
values must be non-zero; tempo and note values must be finite and positive; named notes, MIDI indices, key
signatures, volume, loop counts, offsets, frequency, duration, and backend results are range checked.

### Composition and ownership

The application creates its audio backend, exposes it through `XWalkMusicCallbacks`, and then creates the
controller. The callback context is non-owning and must outlive the controller. All callback entries are
required.

```cpp
AudioBackend backend;
const XWalkHal::XWalkMusicCallbacks callbacks = makeMusicCallbacks();
XWalkHal::XWalkMusic music(&backend, callbacks);
const XWalkHal::float64 frequencyHz = music.noteFrequencyHz("A4");
music.playToneFor(frequencyHz, music.beatDurationSeconds(XHAL_RPI5CAR_MUSIC_QUARTER_NOTE));
```

Construction invokes `enableOutput` so speaker power is active before playback. Destruction does not disable
or release the caller-owned backend.

For Raspberry Pi composition, create dependencies in ownership order and destroy them in reverse order:

```cpp
XWalkHal::XWalkAudioAlsa audio(pcmDevice, mixerDevice, mixerElement);
XWalkHal::XWalkMusicAlsa adapter(audio, nullptr,
    XWalkHal::XWalkMusicSndFileDecoder::operations());
XWalkHal::XWalkMusic music(&adapter, adapter.callbacks());
```

`XWalkAudioAlsa` owns PCM and mixer handles. `XWalkMusicAlsa` only observes that owner and retains decoded
data and at most one background-sound worker plus one streamed-music worker. The adapter must outlive
`XWalkMusic`, and the audio owner must outlive both. Sound effects may temporarily change the shared mixer
volume.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic` —
source directory

## 3. Directory layout

```text
xWalkMusic/
├── CMakeLists.txt                       Libraries, options, host and hardware tests
├── include/
│   ├── xHal_Rpi5CarMusic.h              Public theory, playback, tone, validation, and lifetime contract
│   └── xHal_Rpi5CarMusicTypes.h         Fixed music values and injected audio callback types
├── src/
│   ├── xHal_Rpi5CarMusicLifecycle.cpp   Callback validation, binding, output enable, and destruction
│   ├── xHal_Rpi5CarMusicPlayback.cpp    Sound, streamed music, volume, and transport control
│   ├── xHal_Rpi5CarMusicTheory.cpp      Time signature, tempo, beat, key, and note calculations
│   └── xHal_Rpi5CarMusicTone.cpp        Signed 16-bit little-endian mono PCM generation and output
├── hardware/
│   ├── include/
│   │   ├── xHal_Rpi5CarMusicAlsa.h               Shared-ALSA adapter ownership, callback, worker contract
│   │   ├── xHal_Rpi5CarMusicAlsaTypes.h          Decoded PCM data and injected decoder operation types
│   │   ├── xHal_Rpi5CarMusicSndFileDecoder.h     Stateless optional libsndfile operation provider
│   │   └── xHal_Rpi5CarMusicSndFileDecoderTypes.h  libsndfile decoder types
│   ├── src/
│   │   ├── xHal_Rpi5CarMusicAlsaCallbacks.cpp    Callback routing, volume, transport, and tone output
│   │   ├── xHal_Rpi5CarMusicAlsaDecode.cpp       Bounded RIFF/WAVE chunk parsing and PCM validation
│   │   ├── xHal_Rpi5CarMusicAlsaLifecycle.cpp    Dependency binding, worker shutdown, callback publication
│   │   ├── xHal_Rpi5CarMusicAlsaPlayback.cpp     Period writes, looping, pause, resume, stop observation
│   │   └── xHal_Rpi5CarMusicSndFileDecoder.cpp   Bounded MP3 and audio-file decoding into signed 16-bit PCM
│   └── test/
│       ├── include/xHal_Rpi5CarMusicAlsaTestTypes.h
│       └── src/
│           ├── xHal_Rpi5CarMusicAlsaTest.cpp           Injected decoder and ALSA tests without a device
│           ├── xHal_Rpi5CarMusicAlsaHardwareTest.cpp   Opt-in short five-percent-volume tone test
│           └── xHal_Rpi5CarMusicSndFileDecoderTest.cpp Packaged MP3 decoding without an audio device
├── simulation/                          Silent in-memory backend, trace configuration, and executable
└── test/
    ├── include/xHal_Rpi5CarMusicTestSupport.h   Named audio callbacks shared by host tests
    └── src/
        ├── xHal_Rpi5CarMusicTest.cpp            Callback, theory, playback, tone, and validation tests
        └── xHal_Rpi5CarMusicTestSupport.cpp
```

## 4. Child modules

- [xWalkMusic Simulation](simulation/xWalkMusic%20Simulation.md) — silent executable that composes the public
  Music API over an in-memory callback backend.

## 5. Public interface

`xHal_Rpi5CarMusic.h` in `include`
declares `XWalkMusic(context, callbacks)` with these operation groups:

| Group | Operations |
|---|---|
| Theory | `setTimeSignature`, `timeSignature`, `setKeySignature`, `keySignature`, `setTempo`, `tempo` |
| Timing and notes | `beatDurationSeconds`, `noteFrequencyHz` (MIDI index or note name) |
| Sound effects | `soundPlay`, `soundPlayBackground`, `soundLength` |
| Streamed music | `musicPlay`, `musicSetVolume`, `musicStop`, `musicPause`, `musicResume`, `musicUnpause` |
| Tone | `getToneData`, `playToneFor` |

Music constants such as `XHAL_RPI5CAR_MUSIC_SAMPLE_RATE_HZ` and `XHAL_RPI5CAR_MUSIC_DEFAULT_TEMPO_BPM` are
defined in the shared common header. ALSA adapter and decoder contracts live under `hardware/include`.

## 6. Build

| CMake option | Default | Effect |
|---|---:|---|
| `XWALK_MUSIC_BUILD_HOST_TESTS` | `OFF` | Host tests; also builds the ALSA adapter |
| `XWALK_MUSIC_BUILD_HARDWARE_TESTS` | `OFF` | Hardware-labelled low-volume tone test |
| `XWALK_MUSIC_BUILD_ALSA_BACKEND` | `OFF` | `xWalkMusicAlsa` over `xWalkAudioAlsa` |
| `XWALK_MUSIC_BUILD_SNDFILE_DECODER` | `OFF` | `xWalkMusicSndFileDecoder`; requires the ALSA adapter |

The core `xWalkMusic` static library links `xWalkLibraryCommon` publicly and `xWalkTrace` privately. The ALSA
adapter requires Linux, and the libsndfile decoder fails configuration without libsndfile development files.

Compile the target build, including the optional decoder:

```bash
sudo apt install libasound2-dev libsndfile1-dev
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic/build-rpi -DXWALK_MUSIC_BUILD_HARDWARE_TESTS=ON -DXWALK_MUSIC_BUILD_SNDFILE_DECODER=ON
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic/build-rpi --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic/build-rpi -N -L hardware
```

## 7. Configuration

Before deployment, use `aplay -l`, `aplay -L`, and `amixer scontrols` to select the PCM, mixer device, and
playback element. Do not assume ALSA card zero.

The module uses unique `RPI` identifiers (`RPI.288` through `RPI.307`) for ordinary theory, playback,
transport, and tone operations. Enabled messages are written to the terminal and configured log file. A
selector such as `RPI.303.enable` updates the generated XML catalogue produced by
`simulation/config/xHal_Rpi5CarMusicTraceConfig.py`; later runs load that state without another selector.
The destructor contains no trace or backend operations.

## 8. Testing

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic/build-host -DXWALK_MUSIC_BUILD_HOST_TESTS=ON
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic/build-host --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic/build-host --output-on-failure
```

| CTest name | Label | Scope |
|---|---|---|
| `xWalkMusicHostTest` | `host` | In-memory callback, theory, playback, tone, validation, and trace arguments |
| `xWalkMusicAlsaHostTest` | `host` | Injected decoder and ALSA operation tables with a build-local WAVE fixture |
| `xWalkMusicSndFileDecoderHostTest` | `host` | Packaged MP3 decoding; requires the libsndfile decoder option |
| `xWalkMusicAlsaLowVolumeHardwareTest` | `hardware` | Five-percent mixer volume and a short 220-Hertz tone |

The host suites open no audio device and access no Robot HAT output. The decoder test reads
`xWalkAudioResources/music/slow-trail-Ahjay_Stelino.mp3`.

List the hardware test during normal builds; do not run it. Run it only with explicit approval after
confirming the correct Raspberry Pi, Robot HAT, speaker, and safe volume setup. Optional arguments are PCM
device, mixer device, and mixer element names, in that order.

## 9. Dependencies

- `xWalkLibraryCommon` and `xWalkTrace`; `XWalkDependencies.cmake` from `xWalkLibrary`.
- `xWalkAudio` (`xWalkAudioAlsa`) and ALSA development files for the adapter.
- libsndfile development files for the optional decoder.
- Python 3 for trace catalogue generation in host tests.

## 10. Safety and constraints

- The callback context, adapter, and audio owner must outlive every object that observes them.
- Sound effects may temporarily change the shared mixer volume used by other audio consumers.
- Hardware playback uses five-percent mixer volume and remains opt-in.

## 11. Related notes

- [xWalkHal Layer1](../xWalkHal%20Layer1.md)
- [xWalkHal Layer1 Tests](../test/xWalkHal%20Layer1%20Tests.md)
- [xWalkHal](../../xWalkHal.md)
- [xWalkSpeaker](../xWalkSpeaker/xWalkSpeaker.md)
- [xWalkAudio](../../interface/xWalkAudio/xWalkAudio.md)
- [xWalkAudioResources](../../../xWalkAudioResources/xWalkAudioResources.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../test/xWalkHal%20Layer1%20Tests.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkMusic%20Simulation.md)
