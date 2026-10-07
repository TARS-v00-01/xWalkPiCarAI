<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkVoiceActiveCar

**2. xWalk hardware &middot; Module 42**

<!-- xwalk-page-header:end -->

# xWalkVoiceActiveCar

`xWalkVoiceActiveCar` is the sensor-aware PiCar-X voice Agent. Its `XWalkVoiceActiveCar` coordinator combines
speech or keyboard prompts, ultrasonic sensing, language-model responses, optional images, preset SelfDrive
actions, and Robot HAT status-LED states in one bounded foreground loop. It is the canonical port of upstream
`example/voice_active_car.py` and the shared coordinator reused by
[`xWalkVoiceActiveCarGpt`](../xWalkVoiceActiveCarGpt/xWalkVoiceActiveCarGpt.md).

## 1. Overview

The coordinator owns no physical device or provider backend. Speech recognition and speech synthesis are
injected through the existing xWalk HAL voice-assistant service. On Raspberry Pi, the owning application must
supply Vosk recognition, ALSA capture and playback, Espeak synthesis, the configured language-model HTTP
backend, Music, SelfDrive, speaker power, the Robot HAT status LED, and a deployment-selected CSI or USB camera
according to the selected command.
[`xWalkCameraCapture`](../../xWalkVision/xWalkCameraCapture/xWalkCameraCapture.md) supplies the image callback.
The Agent remains portable and device-free despite the complete target composition, which is wired by the
Controller boot modules in `xWalkBoot`.

The default Rolly profile preserves the upstream behavior:

| Setting | Value |
| --- | --- |
| Name | `Rolly` |
| Wake phrase / wake answer | `hey rolly` / `Hi there` |
| Welcome message | `Hi, I'm Rolly. Wake me up with: hey rolly` |
| Ultrasonic trigger | 10 cm (`tooCloseCm`) |
| Image attachment | Enabled for ordinary rounds |
| Recognition language | `en-us` |
| Listen timeout | 30 000 ms |
| Model | OpenAI `gpt-4o-mini` at `https://api.openai.com/v1/chat/completions` |
| Credential | Read only from `OPENAI_API_KEY` by the Raspberry Pi composition |

The profile also retains the complete upstream instructions, the LED lifecycle, the response parser, and
preset-action dispatch. The instructions list the actions `shake head`, `nod`, `wave hands`, `resist`,
`act cute`, `rub hands`, `think`, `twist body`, `celebrate`, `depressed`, and `stop`, plus the sound effects
`honking` and `start engine`.

### Round sequence

1. When `sensorEnabled` is set and the ultrasonic distance is below `tooCloseCm`, the coordinator builds the
   sensor prompt `<<<Ultrasonic sense too close: <distance>cm>>>`; otherwise it reads a voice or keyboard
   prompt.
2. In wake mode, a case-insensitive wake-phrase match speaks `answerOnWake` with the LED on; the next prompt
   is processed as the request.
3. For an ordinary prompt with `withImage` set and a capture callback present, the callback returns an image
   path. Sensor prompts never capture an image.
4. The prompt and image path are sent to the voice assistant. The response is parsed either as
   `RESPONSE_TEXT` followed by an `ACTIONS: a, b` line, or as a JSON object with `answer` and `actions`.
5. Parsed actions are queued on the SelfDrive worker, the response text is spoken with the LED on, and the
   round waits until SelfDrive reports the actions as complete.

The action-line parser trims whitespace and falls back to the single action `stop` when no `ACTIONS:` line is
present. The JSON parser returns raw text and no actions for malformed input.

### Continuous conversation

The coordinator supports opt-in bounded continuous conversation. A wake phrase opens the session, follow-up
prompts are accepted without another wake phrase, and the existing language-model object retains its
configured history. Idle time, successful-round count, and consecutive recognition misses bound the session.
A trimmed, case-insensitive sleep phrase ends the session before model, camera, or action processing. Every
session exit, cancellation, and terminal error stops vehicle output. Profiles that leave continuous mode
disabled retain the original wake-before-every-request behavior.

### Image attachment

Image attachment is a profile setting changed with `setImageEnabled()`. Disabled profiles do not call the image
callback; the Raspberry Pi composition also avoids constructing the still-camera provider, eliminating camera
startup and capture timeout from text-only rounds.

### Optional web retrieval

When `webSearchEnabled` is set and `XWalkWebSearch::shouldSearch()` accepts an ordinary prompt, the
coordinator calls the injected search callback, validates that source names and URLs have equal counts, appends
the reference text, and prints each source. A round that uses retrieved text always dispatches only `stop`.
A retrieval failure is reported and the prompt instructs the model not to invent current facts or sources.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkVoiceActiveCar` -
source directory

## 3. Directory layout

```text
xWalkVoiceActiveCar/
    CMakeLists.txt                                    Library, config-directory check and host test
    config/
        voice-active-car.jpg                          Deterministic host image
    include/
        xAgent_Rpi5CarVoiceActiveCar.h                Coordinator class and Rolly constants
        xAgent_Rpi5CarVoiceActiveCarTypes.h           Callbacks, configuration, response and enums
    src/
        xAgent_Rpi5CarVoiceActiveCar.cpp              Foreground loop, parsers, session and validation
        xAgent_Rpi5CarVoiceActiveCarProfile.cpp       Rolly instructions and default configuration
    test/
        include/xAgent_Rpi5CarVoiceActiveCarTestSupport.h   Access to protected search validation
        src/xAgent_Rpi5CarVoiceActiveCarTest.cpp            Device-free parser and profile test
```

## 4. Child modules

- [xWalkVoiceActiveCar Configuration](config/xWalkVoiceActiveCar%20Configuration.md) - deterministic host image
  asset and its CMake directory setting.

## 5. Public interface

Public headers in the
`include` directory,
in namespace `xwalk::agent`:

- `xAgent_Rpi5CarVoiceActiveCar.h` - coordinator class and Rolly constants;
- `xAgent_Rpi5CarVoiceActiveCarTypes.h` - callback aliases, configuration, response and enumerations.

| Element | Purpose |
| --- | --- |
| Constructor | Stores non-owning vehicle, SelfDrive, assistant and LED objects; validates the setup |
| `run()` | Runs the foreground loop; returns `0` after normal exit, `1` when SelfDrive actions fail |
| `stop()` | Stops assistant and SelfDrive, closes the vehicle, turns the LED off, resets wake state |
| `assistantConfiguration()` | Rolly instructions and welcome message |
| `carConfiguration()` | Default Rolly coordinator configuration |
| `parseResponse()` | Action-line parser with `stop` fallback |
| `parseJsonResponse()` | JSON `answer` and `actions` parser |
| `matchesWakePhrase()` | Case-insensitive wake-phrase search in a transcript |
| `setInputMode()` | Selects voice or keyboard input before `run()` |
| `setImageEnabled()` | Enables or disables image attachment before `run()` |
| `XWalkVoiceActiveCarCallbacks` | Output, continue, delay, clock, image, keyboard input and web-search callbacks |
| `XWalkVoiceActiveCarConfiguration` | Trigger distance, image, timeouts, wake, input, format, session and search |
| `XWalkVoiceActiveCarResponse` | Spoken text and parsed action names |

The class is neither copyable nor movable. `XWalkPicarx`, `XWalkSelfDrive`, `XWalkVoiceAssistant`, and
`XWalkLed` are passed by reference and stored as non-owning pointers; they and the callback context must
outlive the coordinator.

## 6. Build

The module builds the static library `xWalkVoiceActiveCar` with alias `xWalk::VoiceActiveCar` (C++17, strict
GNU/Clang warnings). When absent, CMake adds `xWalkSelfDrive`, `xWalkVoiceAssistant`, `xWalkLed`, and
`xWalkWebSearch` with their own tests disabled. From the repository root, the aggregate Driver host build
enables this module's host test:

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver -B xWalk-rpi5-hw/xWalkDriver/build-host -DXWALK_AGENT_BUILD_HOST=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/build-host --target xWalkVoiceActiveCarTest
```

## 7. Configuration

| CMake setting | Default | Meaning |
| --- | --- | --- |
| `XWALK_VOICE_ACTIVE_CAR_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkVoiceActiveCarTest` |
| `XWALK_VOICE_ACTIVE_CAR_CONFIG_DIRECTORY` | `<module>/config` | Directory holding `voice-active-car.jpg` |

Configuration fails when the configured directory or `voice-active-car.jpg` is missing. Runtime values for the
Raspberry Pi composition, such as `voice_active_car_model` and `voice_active_car_api_key_environment`, are
kept in `features.conf`.

Physical camera captures use the writable deployment `camera_output` setting.

Constructor validation rejects:

- missing `output`, `shouldContinue`, or `delay` callbacks;
- keyboard input mode without an `input` callback;
- enabled web search without both `webSearch` and `webSearchContext`;
- `tooCloseCm <= 1.0`, a zero listen timeout, or one above the HAL speech-to-text maximum;
- an enabled wake phrase that is empty;
- continuous conversation without wake mode or a clock callback, with an idle timeout of zero or above the
  speech-to-text maximum, with rounds outside 1 to 100, misses outside 1 to 10, or no sleep phrases;
- empty or duplicate normalized sleep phrases.

## 8. Testing

`xWalkVoiceActiveCarHostTest` (label `host`) checks both response parsers, the Rolly profile and instructions,
the configured JPEG signature from `XWALK_VOICE_ACTIVE_CAR_CONFIG_DIRECTORY`, and web-search response
validation. The test reads the module-local image instead of referring to `/tmp`.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-host --output-on-failure -R xWalkVoiceActiveCarHostTest
```

The module defines no hardware test. The voice group hardware-profile test is described in
[xWalkVoice](../xWalkVoice.md); list it with `ctest -N -L hardware` and run it only with explicit approval and
a confirmed safe Raspberry Pi and Robot HAT setup.

## 9. Dependencies

- [xWalkSelfDrive](../../xWalkVehicle/xWalkSelfDrive/xWalkSelfDrive.md) - action worker and status states.
- [xWalkPicarx](../../xWalkVehicle/xWalkPicarx/xWalkPicarx.md) - vehicle control, distance and safety guard.
- [xWalkVoiceAssistant](../../../xWalkHal/layer1/xWalkVoiceAssistant/xWalkVoiceAssistant.md) - recognition,
  model request and speech synthesis.
- [xWalkLed](../../../xWalkHal/sensor/xWalkLed/xWalkLed.md) - Robot HAT status LED.
- [xWalkWebSearch](../../../xWalkHal/interface/xWalkWebSearch/xWalkWebSearch.md) - bounded retrieval types.
- `xWalkTrace` - private trace support.

## 10. Safety and constraints

- `run()` holds an `XWalkPicarxSafetyGuard` for the vehicle.
- Model failure stops the vehicle, ends the session, turns the LED off, and returns to wake mode.
- Session exit, cancellation, terminal errors, and `stop()` stop vehicle output.
- Sleep phrases are matched before any camera, model, or action processing.
- Retrieved web text never moves the vehicle; retrieval-assisted rounds dispatch only `stop`.
- The OpenAI credential is read only from the environment and is never stored in tracked configuration.

## 11. Related notes

- [xWalkVoice](../xWalkVoice.md) - voice Agent group.
- [xWalkVoiceActiveCarGpt](../xWalkVoiceActiveCarGpt/xWalkVoiceActiveCarGpt.md) - Jarvis profile over this
  coordinator.
- [xWalkVoicePromptCar](../xWalkVoicePromptCar/xWalkVoicePromptCar.md) - spoken movement demonstration from
  upstream example 14.
- [xWalkVoiceControlledCar](../xWalkVoiceControlledCar/xWalkVoiceControlledCar.md) - wake-word movement port
  from upstream example 16.
- [xWalkCameraCapture](../../xWalkVision/xWalkCameraCapture/xWalkCameraCapture.md) - still-image callback.

---

[Previous page](../xWalkTextVisionTalk/xWalkTextVisionTalk.md) · [Chapter index](../../../../index.md) · [Next page](config/xWalkVoiceActiveCar%20Configuration.md)
