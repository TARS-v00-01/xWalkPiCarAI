<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkAudio

**2. xWalk hardware &middot; Module 68**

<!-- xwalk-page-header:end -->

# xWalkAudio

`xWalkAudio` provides shared Linux ALSA PCM playback and mixer ownership for xWalk audio consumers. It keeps
libasound out of the hardware-independent Music, Speaker, GPT, and VoiceAssistant targets.

## 1. Overview

`XWalkAudioAlsa` owns one configured mixer for its complete lifetime and up to eight PCM playback handles opened
on demand. All public operations are serialized by one internal mutex. The class validates sample format, rate,
channel count, period size, latency, and payload length; completes short writes; and bounds ALSA underrun
recovery to three attempts.

The PCM, mixer, and simple-element names are deployment configuration. The defaults are `default`, `default`,
and `PCM`; they do not assume ALSA card zero. Use `aplay -l`, `aplay -L`, and `amixer scontrols` on the deployed
Raspberry Pi to identify the overlay-provided device and playback element.

This module establishes shared resource ownership only. Music and Speaker callback adapters remain separate work
so neither feature module depends on the other. Create the audio backend before every adapter or consumer and
destroy it after they have stopped all playback workers and closed their streams.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio` -
source directory

## 3. Directory layout

```text
xWalkAudio/
    CMakeLists.txt                                   Interface target, ALSA backend, and test options
    include/
        xHal_Rpi5CarAudioTypes.h                     Stream configuration and injected ALSA operation seam
    hardware/
        include/xHal_Rpi5CarAudioAlsa.h              ALSA PCM and mixer ownership interface
        src/xHal_Rpi5CarAudioAlsa.cpp                Stream, write, recovery, and mixer behavior
        src/xHal_Rpi5CarAudioAlsaLifecycle.cpp       Validation and deterministic cleanup
        src/xHal_Rpi5CarAudioAlsaSystem.cpp          Real libasound operations
        test/include/xHal_Rpi5CarAudioAlsaTestSupport.h   Test state and callback declarations
        test/src/xHal_Rpi5CarAudioAlsaTest.cpp       Injected software-test scenarios
        test/src/xHal_Rpi5CarAudioAlsaTestSupport.cpp     Injected device-free operation implementations
        test/src/xHal_Rpi5CarAudioAlsaHardwareTest.cpp    Opt-in silent hardware test
    simulation/
        CMakeLists.txt                               Standalone simulation project
        config/xHal_Rpi5CarAudioTraceConfig.py       Persistent trace-catalogue generator
        include/                                     Handler, host stub, arguments, and composition declarations
        src/                                         Stub and hardware composition and trace arguments
```

| File | Responsibility |
| --- | --- |
| `xHal_Rpi5CarAudioTypes.h` | Declares PCM configuration and injected ALSA operations. |
| `xHal_Rpi5CarAudioAlsa.h` | Declares bounded PCM and persistent mixer ownership. |
| `xHal_Rpi5CarAudioAlsa.cpp` | Completes writes and bounds underrun recovery. |
| `xHal_Rpi5CarAudioAlsaLifecycle.cpp` | Validates and releases all handles. |
| `xHal_Rpi5CarAudioAlsaSystem.cpp` | Maps the operation seam to libasound. |
| `xHal_Rpi5CarAudioAlsaTest.cpp` | Tests ownership without opening a sound device. |
| `xHal_Rpi5CarAudioAlsaTestSupport.h` | Declares reusable Audio test state and operations. |
| `xHal_Rpi5CarAudioAlsaTestSupport.cpp` | Implements injected device-free Audio operations. |
| `xHal_Rpi5CarAudioAlsaHardwareTest.cpp` | Writes silence through configured hardware. |

## 4. Child modules

- [xWalkAudio Simulation](simulation/xWalkAudio%20Simulation.md) - standalone executable that runs representative
  Audio operations through a safe host stub or an opt-in ALSA backend.

## 5. Public interface

Headers live in `include` and
`hardware/include`.

- `xHal_Rpi5CarAudioTypes.h`
  declares `XWalkAudioSampleFormat` (`Signed16LittleEndian`, `Float32LittleEndian`),
  `XWalkAudioStreamConfiguration`, the opaque `audiopcmhandle` and `audiomixerhandle` aliases, and the
  `XWalkAudioAlsaOperations` callback table.
- `xHal_Rpi5CarAudioAlsa.h`
  declares `XWalkAudioAlsa` with `openStream`, `writeFrames`, `closeStream`, `setVolume`, and
  `openStreamCount`. A second constructor accepts an injected operation table and nullable non-owning context.

| Stream parameter | Unit | Valid range |
| --- | --- | --- |
| `sampleRateHz` | Hertz | Positive |
| `channelCount` | Interleaved channels | 1 through 8 |
| `periodFrames` | Frames | 1 through 4,096 |
| `latencyUs` | Microseconds | Positive; default 100,000 |
| `setVolume` | Percent | 0 through 100 |

The stream limit, default latency, and recovery-attempt count come from `XHAL_RPI5CAR_AUDIO_MAXIMUM_STREAM_COUNT`
(8), `XHAL_RPI5CAR_AUDIO_DEFAULT_LATENCY_US`, and `XHAL_RPI5CAR_AUDIO_RECOVERY_ATTEMPT_COUNT` (3) in the common
library. The backend is neither copyable nor movable because callback contexts and handles retain identity.
Invalid arguments raise `std::invalid_argument` or `std::out_of_range`; ALSA failures raise
`std::runtime_error`.

## 6. Build

The CMake project defines these targets:

| Target | Kind | Condition |
| --- | --- | --- |
| `xWalkAudio` | `INTERFACE` library with the public `include` directory | Always |
| `xWalkAudioAlsa` | Static ALSA backend linking `ALSA::ALSA` | Any option below is `ON` |
| `xWalkAudioAlsaTest` | Host test executable | `XWALK_AUDIO_BUILD_HOST_TESTS` |
| `xWalkAudioAlsaHardwareTest` | Hardware test executable | `XWALK_AUDIO_BUILD_HARDWARE_TESTS` |

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_AUDIO_BUILD_HOST_TESTS` | `OFF` | Builds the injected ALSA software test |
| `XWALK_AUDIO_BUILD_HARDWARE_TESTS` | `OFF` | Builds the silent hardware test |
| `XWALK_AUDIO_BUILD_LINUX_BACKEND` | `OFF` | Builds `xWalkAudioAlsa` without tests |

Every option requires Linux and the ALSA development package; configuration fails on other systems. The
repository-level `xWalk-rpi5-hw/CMakeLists.txt` also adds this module to the aggregate build.

Backend-only build from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio -B xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/build-linux -DXWALK_AUDIO_BUILD_LINUX_BACKEND=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/build-linux --parallel
```

## 7. Testing

The host test links libasound so the real backend is compile-checked, but it injects every ALSA operation and
does not open a sound device or change volume. It also compiles the simulation handler, host stub, and argument
parser. CTest registers it as `xWalkAudioAlsaSoftwareTest` with label `host`.

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio -B xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/build-host -DXWALK_AUDIO_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/build-host -L host --output-on-failure
```

The host test and simulation use trace macros for terminal and log output. A successful trace selector updates
the generated module XML, and later runs load that saved state without requiring the selector again. Test logs
are written to `build-host/log/xWalkAudioTest.log`.

The hardware test `xWalkAudioAlsaSilentHardwareTest` carries label `hardware`. Configure and list it only:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio -B xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/build-rpi -DXWALK_AUDIO_BUILD_HARDWARE_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkAudio/build-rpi -N -L hardware
```

The registered test opens the configured ALSA devices, writes 256 zero-valued mono frames at 44,100 Hertz,
drains and closes the PCM stream, and sets playback volume to fifty percent. It emits no audible sample, but it
remains opt-in because it claims a physical audio device and changes mixer state. To select non-default
deployment names, the executable accepts `PCM_DEVICE MIXER_DEVICE MIXER_ELEMENT`; run it only after explicit
approval and a completed hardware safety review.

The aggregate [xWalkHal Interface Tests](../test/xWalkHal%20Interface%20Tests.md) and
[xGoogleTest](../../xWalkTest/xGoogleTest/xGoogleTest.md) suites reuse the Audio test support sources.

## 8. Dependencies

- `xWalkLibraryCommon` for project types and audio constants.
- `xWalkTrace` for trace macros (private to `xWalkAudioAlsa`).
- ALSA (`find_package(ALSA)`) and Python 3 for the host-test trace catalogue.

## 9. Safety and constraints

- The software test never opens a sound device. The hardware test changes mixer state and is opt-in.
- Consumers must close their streams and stop playback workers before the backend is destroyed.
- A non-null injected operation context must outlive the backend.

## 10. Related notes

- [xWalkHal Interface Layer](../xWalkHal%20Interface%20Layer.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalkSpeaker](../../layer1/xWalkSpeaker/xWalkSpeaker.md)
- [xWalkMusic](../../layer1/xWalkMusic/xWalkMusic.md)
- [xWalkGPT](../../layer1/xWalkGPT/xWalkGPT.md)

---

[Previous page](../xWalkHal%20Interface%20Layer.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkAudio%20Simulation.md)
