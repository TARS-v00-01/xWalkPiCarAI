<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkVoicePromptCar

**2. xWalk hardware &middot; Module 46**

<!-- xwalk-page-header:end -->

# xWalkVoicePromptCar

`xWalkVoicePromptCar` ports upstream `example/14.voice_promt_car.py` through caller-owned `XWalkPicarx` and
`XWalkTextToSpeech` objects. It speaks the source greeting, then announces and performs forward, backward,
left, and right movements.

## 1. Overview

`XWalkVoicePromptCar::run()` speaks `Hello! I'm PiCar-X.` and then performs four bounded steps, each preceded by
a `shouldContinue` check and a spoken announcement:

| Step | Announcement | Steering | Motion |
| --- | --- | --- | --- |
| 1 | `Moving forward` | Centred | Forward |
| 2 | `Moving backward` | Centred | Backward |
| 3 | `Turning left` | Minus 20 degrees | Forward |
| 4 | `Turning right` | Plus 20 degrees | Forward |

Each step runs at a 30-percent requested speed for two seconds, then stops the motors; turns also restore
centred steering. The left and right movements preserve the source's minus and plus 20-degree steering.

Normal completion, cancellation between movements, and exceptions all stop the motors and restore centred
steering. On completion the Agent prints `Voice-prompt car demonstration stopped`. The Agent owns no physical
motor, speaker, ALSA endpoint, Espeak process, or application callback.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkVoicePromptCar` -
source directory

## 3. Directory layout

```text
xWalkVoicePromptCar/
    CMakeLists.txt                                  Static library and dependency wiring
    include/
        xAgent_Rpi5CarVoicePromptCar.h              Agent class
        xAgent_Rpi5CarVoicePromptCarTypes.h         Callbacks and configuration
    src/
        xAgent_Rpi5CarVoicePromptCar.cpp            Demonstration sequence, drive and turn steps
        xAgent_Rpi5CarVoicePromptCarLifecycle.cpp   Constructor and validation
```

## 4. Public interface

Headers are in the
`include` directory,
namespace `xwalk::agent`.

| Element | Purpose |
| --- | --- |
| Constructor | Stores non-owning `XWalkPicarx` and `XWalkTextToSpeech` objects and validates the setup |
| `run()` | Runs the four-step demonstration; returns `0` after completion or cancellation |
| `stop()` | Stops the motors and centres steering |
| `XWalkVoicePromptCarCallbacks` | `output`, `shouldContinue`, and `delay` callbacks |
| `XWalkVoicePromptCarConfiguration` | Speed, steering angle, and per-step drive duration |

The class is neither copyable nor movable. The vehicle, text-to-speech object, and callback context must
outlive the Agent.

## 5. Build

The module builds the static library `xWalkVoicePromptCar` with alias `xWalk::VoicePromptCar` (C++17, strict
GNU/Clang warnings). It links `xWalkPicarx` and `xWalkGPT` publicly and `xWalkTrace` privately. When absent,
CMake adds `xWalkPicarx` with its tests disabled and `xWalkGPT` with its host test and the ALSA, Vosk, and
Espeak providers disabled. The module is built through the voice group or the aggregate Driver build:

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver -B xWalk-rpi5-hw/xWalkDriver/build-host -DXWALK_AGENT_BUILD_HOST=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/build-host --target xWalkVoicePromptCar
```

## 6. Configuration

`XWalkVoicePromptCarConfiguration` defaults and constructor validation:

| Field | Default | Valid range |
| --- | --- | --- |
| `speedPercent` | 30.0 % | Finite, 0 to 100 |
| `steeringAngle` | 20.0 degrees | Finite, greater than 0 and at most 40 |
| `driveDurationMs` | 2000 ms | Greater than 0 |

All three callbacks are required. The module defines no CMake option of its own.

## 7. Testing

The module has no dedicated test target. The voice group host test and hardware-profile test cover the public
type; see [xWalkVoice](../xWalkVoice.md). List hardware tests with `ctest -N -L hardware` and run them only with
explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md) - vehicle control and safety guard.
- [xWalkGPT](../../../xWalkHal/layer1/xWalkGPT/xWalkGPT.md) - `XWalkTextToSpeech` service.
- `xWalkTrace` - private trace support.

## 9. Safety and constraints

- `run()` holds an `XWalkPicarxSafetyGuard` and calls `stop()` before returning.
- Cancellation is checked between steps; a started step completes its full `driveDurationMs` delay.
- Every step stops the motors after its delay.

## 10. Related notes

- [xWalkVoice](../xWalkVoice.md) - voice Agent group.
- [xWalkVoiceControlledCar](../xWalkVoiceControlledCar/xWalkVoiceControlledCar.md) - wake-word movement port.
- [xWalkVoiceActiveCar](../xWalkVoiceActiveCar/xWalkVoiceActiveCar.md) - sensor-aware language-model voice car.

---

[Previous page](../xWalkVoiceControlledCar/xWalkVoiceControlledCar.md) · [Chapter index](../../../../index.md) · [Next page](../../../xWalkHal/xWalkHal.md)
