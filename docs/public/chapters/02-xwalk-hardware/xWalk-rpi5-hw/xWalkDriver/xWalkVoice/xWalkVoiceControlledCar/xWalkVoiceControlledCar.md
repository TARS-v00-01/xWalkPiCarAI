<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) /
xWalkVoiceControlledCar

**2. xWalk hardware &middot; Module 45**

<!-- xwalk-page-header:end -->

# xWalkVoiceControlledCar

`xWalkVoiceControlledCar` ports upstream `example/16.voice_controlled_car.py` through caller-owned
`XWalkPicarx` and `XWalkSpeechToText` objects. It waits for "hey robot", accepts repeated forward, backward,
left, and right commands, and returns to wake-word listening when it hears "sleep".

## 1. Overview

`XWalkVoiceControlledCar::run()` alternates between two listening states:

1. **Wake listening.** Each bounded recognition is searched case-insensitively for the wake word. A match
   prints `Wake word detected! Listening...`; other transcripts are ignored.
2. **Command listening.** Each non-empty transcript is printed as `Heard: <text>` and classified. The sleep
   word is checked first, then `forward`, `backward`, `left`, and `right` as substrings. A sleep command stops
   the motors, centres the steering, and returns to wake listening.

Movement preserves the source behavior: straight movement uses centred steering, and turns use minus or plus
25 degrees while driving forward. Each movement runs at a 30-percent requested speed for one second and then
stops the motors; turns also re-centre the steering. Movement timing uses 20-millisecond cancellation slices
while preserving each source one-second interval. Empty and unknown transcripts do not move the car.

Normal exit, cancellation, and exceptions stop recognition and leave the motors stopped with centred steering.
The Agent owns no motor, microphone, ALSA endpoint, Vosk model, or application callback.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkVoiceControlledCar` -
source directory

## 3. Directory layout

```text
xWalkVoiceControlledCar/
    CMakeLists.txt                                      Static library and dependency wiring
    include/
        xAgent_Rpi5CarVoiceControlledCar.h              Agent class
        xAgent_Rpi5CarVoiceControlledCarTypes.h         Callbacks, command enumeration and configuration
    src/
        xAgent_Rpi5CarVoiceControlledCar.cpp            Wake and command loop, classification, movement
        xAgent_Rpi5CarVoiceControlledCarLifecycle.cpp   Constructor, normalization and validation
```

## 4. Public interface

Headers are in the
`include` directory,
namespace `xwalk::agent`.

| Element | Purpose |
| --- | --- |
| Constructor | Stores non-owning `XWalkPicarx` and `XWalkSpeechToText` objects and validates the setup |
| `run()` | Runs the wake and command loop; returns `0` after the loop ends |
| `stop()` | Stops recognition and motors and centres steering |
| `classifyCommand()` | Returns `Sleep`, `Forward`, `Backward`, `Left`, `Right`, or `Unknown` |
| `containsWakeWord()` | Case-insensitive wake-word search |
| `XWalkVoiceControlledCarCallbacks` | `output`, `shouldContinue`, and `delay` callbacks |
| `XWalkVoiceControlledCarConfiguration` | Wake and sleep words, speed, steering, drive and listen durations |

The class is neither copyable nor movable. The vehicle, speech-to-text object, and callback context must outlive
the Agent.

## 5. Build

The module builds the static library `xWalkVoiceControlledCar` with alias `xWalk::VoiceControlledCar` (C++17,
strict GNU/Clang warnings). It links `xWalkPicarx` and `xWalkGPT` publicly and `xWalkTrace` privately. When
absent, CMake adds `xWalkPicarx` with its tests disabled and `xWalkGPT` with its host test and the ALSA, Vosk,
and Espeak providers disabled. The module is built through the voice group or the aggregate Driver build:

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver -B xWalk-rpi5-hw/xWalkDriver/build-host -DXWALK_AGENT_BUILD_HOST=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/build-host --target xWalkVoiceControlledCar
```

## 6. Configuration

`XWalkVoiceControlledCarConfiguration` defaults and constructor validation:

| Field | Default | Valid range |
| --- | --- | --- |
| `wakeWord` | `hey robot` | Non-empty |
| `sleepWord` | `sleep` | Non-empty |
| `speedPercent` | 30.0 % | Finite, 0 to 100 |
| `steeringAngle` | 25.0 degrees | Finite, greater than 0 and at most 40 |
| `driveDurationMs` | 1000 ms | Greater than 0 |
| `listenTimeoutMs` | 5000 ms | Greater than 0, at most the HAL speech-to-text maximum |

All three callbacks are required. The module defines no CMake option of its own.

## 7. Testing

The module has no dedicated test target. The voice group host test and hardware-profile test cover the public
type; see [xWalkVoice](../xWalkVoice.md). List hardware tests with `ctest -N -L hardware` and run them only with
explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md) - vehicle control and safety guard.
- [xWalkGPT](../../../xWalkHal/layer1/xWalkGPT/xWalkGPT.md) - `XWalkSpeechToText` service.
- `xWalkTrace` - private trace support.

## 9. Safety and constraints

- `run()` holds an `XWalkPicarxSafetyGuard` and calls `stop()` before returning.
- Each movement is bounded by `driveDurationMs` and checks `shouldContinue` every 20 ms.
- The sleep word takes precedence over movement words in the same transcript.
- Only recognized commands move the vehicle.

## 10. Related notes

- [xWalkVoice](../xWalkVoice.md) - voice Agent group.
- [xWalkVoicePromptCar](../xWalkVoicePromptCar/xWalkVoicePromptCar.md) - spoken movement demonstration.
- [xWalkVoiceActiveCar](../xWalkVoiceActiveCar/xWalkVoiceActiveCar.md) - sensor-aware language-model voice car.

---

[Previous page](../xWalkVoiceActiveCarGpt/xWalkVoiceActiveCarGpt.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkVoicePromptCar/xWalkVoicePromptCar.md)
