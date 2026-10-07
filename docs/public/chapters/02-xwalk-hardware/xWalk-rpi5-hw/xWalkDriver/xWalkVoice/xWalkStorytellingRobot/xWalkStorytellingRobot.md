<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkStorytellingRobot

**2. xWalk hardware &middot; Module 40**

<!-- xwalk-page-header:end -->

# xWalkStorytellingRobot

`xWalkStorytellingRobot` ports upstream `example/15.storytelling_robot.py` through caller-owned PiCar-X and
text-to-speech services. It preserves the Piper greeting, two three-second forward legs with jokes, the
farewell, and the final six-second backward trip at 30-percent requested speed.

## 1. Overview

`run()` performs this bounded sequence:

1. speak the greeting;
2. drive forward for `outwardLegDurationMs`, stop, and speak the first joke;
3. drive forward again, stop, and speak the second joke;
4. speak the farewell, drive backward for `homeLegDurationMs`, and stop.

Continuation is checked before every leg. Long movements wait in 20-millisecond cancellation slices. Completion,
cancellation, and exceptions stop both motors and centre steering: `stop()` stops the PiCar-X and sets the
direction servo to 0 degrees, and an `XWalkPicarxSafetyGuard` performs a non-throwing emergency stop when
`run()` leaves scope. `run()` returns zero.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkStorytellingRobot`
(source directory)

## 3. Directory layout

```text
xWalkStorytellingRobot/
    CMakeLists.txt                                      Static library and alias
    include/
        xAgent_Rpi5CarStorytellingRobot.h               Coordinator class
        xAgent_Rpi5CarStorytellingRobotTypes.h          Callbacks and example 15 configuration
    src/
        xAgent_Rpi5CarStorytellingRobot.cpp             Movement and narration sequence, stop
        xAgent_Rpi5CarStorytellingRobotLifecycle.cpp    Construction, validation, and sliced waiting
```

## 4. Public interface

Headers `xAgent_Rpi5CarStorytellingRobot.h` and `xAgent_Rpi5CarStorytellingRobotTypes.h`
are in the
include directory.

| Element | Contract |
| --- | --- |
| Constructor | Binds caller-owned `XWalkPicarx` and `hal::XWalkTextToSpeech`, context, callbacks, settings |
| `run()` | Runs the bounded sequence; returns zero |
| `stop()` | Stops the motors and centres steering |

`XWalkStorytellingRobotCallbacks` contains `delay` (milliseconds) and `shouldContinue`; both are required.
`XWalkStorytellingRobotConfiguration` defaults:

| Field | Default | Valid range |
| --- | --- | --- |
| `speedPercent` | 30.0 % | finite, 0 to 100 |
| `outwardLegDurationMs` | 3 000 ms | 1 to 60 000 ms |
| `homeLegDurationMs` | 6 000 ms | 1 to 60 000 ms |
| `greeting`, `firstJoke`, `secondJoke`, `farewell` | Example 15 text | non-empty |

Construction raises an invalid-argument error for a missing callback, an empty text, or a non-finite speed, and
an out-of-range error for a value outside the ranges above. The PiCar-X, text-to-speech service, and context are
non-owning and must outlive the coordinator. Copy and move operations are deleted.

## 5. Build

CMake target `xWalkStorytellingRobot` (alias `xWalk::StorytellingRobot`) is a C++17 static library. When
`xWalkPicarx` or `xWalkGPT` is not already defined, the project adds it with tests and native audio and speech
providers disabled. The module defines no standalone test option; build it through the voice group or the
`xWalkDriver` aggregate.

## 6. Configuration

The Raspberry Pi composition in `xWalkBoot` uses the deployment-selected Piper executable, playback tool, and
model (`voice_piper_executable`, `voice_piper_playback_executable`, `voice_piper_model`). The source example uses
the Piper model `en_US-amy-low`. Host verification injects speech and timing without opening audio or moving
hardware.

## 7. Testing

The module has no own test executable. The voice group host test case `XWalkAgentVoiceGroup.StorytellingRobot`
checks the 3 000 ms and 6 000 ms leg durations and a non-empty greeting:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/xWalkVoice/build-host --output-on-failure -L host
```

The voice group hardware-profile test only checks that the class type is available; list it with
`ctest -N -L hardware` and never run it without explicit approval and a confirmed safe Raspberry Pi and Robot
HAT setup.

## 8. Dependencies

- `xWalkPicarx` (public) from `xWalkDriver/xWalkVehicle/xWalkPicarx`.
- `xWalkGPT` (public) from `xWalkHal/layer1/xWalkGPT` for the text-to-speech coordinator.
- `xWalkTrace` (private) for the `RPIAGENT.040` sequence trace.

## 9. Safety and constraints

- The sequence moves the vehicle forward for two legs and backward for one leg; provide clear space on both
  sides before any hardware run.
- Every exit path stops the motors and centres steering.
- Traces exclude spoken text.

## 10. Related notes

- [xWalkVoice](../xWalkVoice.md)
- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md)
- [xWalkGPT](../../../xWalkHal/layer1/xWalkGPT/xWalkGPT.md)
- xWalkBoot source directory
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkOnlineLlmTest/xWalkOnlineLlmTest.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkTextVisionTalk/xWalkTextVisionTalk.md)
