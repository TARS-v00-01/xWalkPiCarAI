<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xSequenceTest

**2. xWalk hardware &middot; Module 50**

<!-- xwalk-page-header:end -->

# xSequenceTest

`xSequenceTest` contains bounded HAL sequence and integration tests ported from the upstream Robot HAT test
scripts. Each sequence is split into host-testable core behavior and opt-in physical-hardware composition.

## 1. Overview

The `core` layer implements every sequence against injected HAL interfaces and is built as one static library per
sequence. Its in-memory verification sources are compiled into [`xGoogleTest`](../xGoogleTest/xGoogleTest.md) as
the host suite `TEST_SUITE_XWALK_SEQUENCE`. The `hardware` layer composes the core sequences with the Linux GPIO,
I2C, and ALSA backends and is linked into the `xSequenceTest` executable, which exists only in the Raspberry Pi
profile.

The Raspberry Pi runner accepts a selector by itself and loads its board and bounded arguments from
`config/xHal_Rpi5CarSequenceTestConfig.yml`. Explicit positional arguments remain supported as a compatibility
override. Every upstream infinite loop is replaced by a required, validated bound.

| Selector | Host case | Upstream source | Physical effect |
| --- | --- | --- | --- |
| `button-event` | `ButtonEvent` | `robot-hat/tests/button_event_test.py` | Claims GPIO17 as input |
| `init-angles` | `InitAngles` | `robot-hat/tests/init_angles_test.py` | Resets MCU, moves three servos |
| `motor-robothat5` | `RobotHat5Motor` | `robot-hat/tests/motor_robothat5_test.py` | Drives four motors |
| `servo-hat` | `ServoHat` | `robot-hat/tests/servo_hat_test.py` | Resets MCU, moves 16 servos, reads ADC |
| `servo` | `Servo` | `robot-hat/tests/servo_test.py` | Moves 12 servos |
| `motor` | `Motor` | `robot-hat/tests/motor_test.py` | Drives two motors |
| (none) | `PiperStream` | `robot-hat/tests/test_piper_stream.py` | Host only |
| `tone` | `Tone` | `robot-hat/tests/tone_test.py` | About 48 seconds of audio |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/xWalkTest/xSequenceTest` —
source directory

## 3. Directory layout

```text
xSequenceTest/
├── CMakeLists.txt        Core libraries, RPI adapters, xSequenceTest executable, hardware CTest entries
├── main.cpp              The module's only process entry point
├── config/
│   ├── xHal_Rpi5CarSequenceTestConfig.yml   Default board, AI, and formal sequence arguments
│   ├── test_config.xml                      Enabled-by-default host selection manifest
│   └── hardware_test_config.xml             Disabled-by-default hardware selection manifest
├── core/
│   ├── include/          Sequence contracts and per-sequence *TestTypes.h test records
│   └── src/              Platform-independent sequences and their in-memory tests
└── hardware/
    ├── include/          Linux composition and central CLI dispatch contracts
    └── src/              Physical GPIO, I2C, PWM, motor, servo, ADC, and ALSA adapters
```

| Path | Responsibility |
| --- | --- |
| `core/include/xHal_Rpi5CarButtonEventSequence.h` | Callback-driven sequence API |
| `core/src/xHal_Rpi5CarButtonEventSequence.cpp` | Platform-independent event flow |
| `core/src/xHal_Rpi5CarButtonEventSequenceTest.cpp` | In-memory host verification |
| `core/include/xHal_Rpi5CarInitAnglesSequence.h` | Initialization-angle sequence API |
| `core/src/xHal_Rpi5CarInitAnglesSequence.cpp` | MCU reset and three-servo initialization flow |
| `core/src/xHal_Rpi5CarInitAnglesSequenceTest.cpp` | In-memory initialization-angle verification |
| `core/include/xHal_Rpi5CarRobotHat5MotorSequence.h` | Bounded four-motor sequence API |
| `core/src/xHal_Rpi5CarRobotHat5MotorSequence.cpp` | Direction phases and fail-safe cleanup |
| `core/src/xHal_Rpi5CarRobotHat5MotorSequenceTest.cpp` | In-memory phase and cleanup verification |
| `core/include/xHal_Rpi5CarMotorSequence.h` | Bounded two-motor sequence API |
| `core/src/xHal_Rpi5CarMotorSequence.cpp` | PWM-and-direction phases and fail-safe cleanup |
| `core/src/xHal_Rpi5CarMotorSequenceTest.cpp` | In-memory pin, phase, and cleanup verification |
| `core/include/xHal_Rpi5CarServoHatSequence.h` | Bounded 16-servo and five-ADC sequence API |
| `core/src/xHal_Rpi5CarServoHatSequence.cpp` | Reset, sweep, and bounded sampling flow |
| `core/src/xHal_Rpi5CarServoHatSequenceTest.cpp` | In-memory sweep and ADC verification |
| `core/include/xHal_Rpi5CarServoSequence.h` | Bounded 12-channel servo-sweep API |
| `core/src/xHal_Rpi5CarServoSequence.cpp` | Ordered negative and positive sweep flow |
| `core/src/xHal_Rpi5CarServoSequenceTest.cpp` | In-memory channel-order and angle verification |
| `core/include/xHal_Rpi5CarPiperStreamSequence.h` | Injected Piper comparison contract and source text |
| `core/src/xHal_Rpi5CarPiperStreamSequence.cpp` | Streamed/buffered request and timing order |
| `core/src/xHal_Rpi5CarPiperStreamSequenceTest.cpp` | In-memory mode, timing, and reporting verification |
| `core/include/xHal_Rpi5CarToneSequence.h` | Immutable melody events and sequence API |
| `core/src/xHal_Rpi5CarToneSequence.cpp` | Volume, tempo, measure, and tone playback order |
| `core/src/xHal_Rpi5CarToneSequenceTest.cpp` | In-memory melody and generated-PCM verification |
| `core/include/xHal_Rpi5Car*SequenceTestTypes.h` | Header-owned test records for each sequence test |
| `hardware/include/xHal_Rpi5CarButtonEventSequenceLinux.h` | Linux callback adapter API |
| `hardware/src/xHal_Rpi5CarButtonEventSequenceLinux.cpp` | Clock, wait, and console adapters |
| `hardware/include/xHal_Rpi5CarInitAnglesSequenceLinux.h` | Linux init-angle composition API |
| `hardware/src/xHal_Rpi5CarInitAnglesSequenceLinux.cpp` | Physical GPIO, I2C, PWM, and servo composition |
| `hardware/include/xHal_Rpi5CarRobotHat5MotorSequenceLinux.h` | Linux motor composition API |
| `hardware/src/xHal_Rpi5CarRobotHat5MotorSequenceLinux.cpp` | Physical dual-PWM motor composition |
| `hardware/include/xHal_Rpi5CarMotorSequenceLinux.h` | Linux two-motor composition API |
| `hardware/src/xHal_Rpi5CarMotorSequenceLinux.cpp` | Physical PWM-and-direction motor composition |
| `hardware/include/xHal_Rpi5CarServoHatSequenceLinux.h` | Linux servo-sequence composition API |
| `hardware/src/xHal_Rpi5CarServoHatSequenceLinux.cpp` | Physical servo/ADC composition and reporting |
| `hardware/include/xHal_Rpi5CarServoSequenceLinux.h` | Linux 12-channel servo composition API |
| `hardware/src/xHal_Rpi5CarServoSequenceLinux.cpp` | Physical PWM and servo composition |
| `hardware/include/xHal_Rpi5CarToneSequenceLinux.h` | Linux ALSA tone-composition API |
| `hardware/src/xHal_Rpi5CarToneSequenceLinux.cpp` | Physical music/ALSA composition and measure output |
| `hardware/include/xHal_Rpi5CarSequenceTestRunner.h` | Central sequence CLI dispatch contract |
| `hardware/src/xHal_Rpi5CarSequenceTestRunner.cpp` | Usage, validation, selection, and Linux dispatch |

## 4. Public interface

### Libraries

| Target | Layer | Public dependencies |
| --- | --- | --- |
| `xWalkButtonEventSequence` | core | `xWalkGpio` |
| `xWalkInitAnglesSequence` | core | `xWalkBoardControl`, `xWalkRobot` |
| `xWalkRobotHat5MotorSequence` | core | `xWalkMotor` |
| `xWalkMotorSequence` | core | `xWalkMotor` |
| `xWalkServoHatSequence` | core | `xWalkAdc`, `xWalkBoardControl`, `xWalkServo` |
| `xWalkServoSequence` | core | `xWalkServo` |
| `xWalkPiperStreamSequence` | core | `xWalkLibraryCommon` |
| `xWalkToneSequence` | core | `xWalkMusic` |
| `xWalk*SequenceLinux` | hardware (RPI) | Core sequence plus Linux GPIO, I2C, or ALSA music backend |
| `xWalkSequenceTestRunner` | hardware (RPI) | `xWalkLibraryCommon`; privately the Linux adapters and yaml-cpp |

### Command line

```sh
./build-rpi/xSequenceTest button-event
./build-rpi/xSequenceTest --config /etc/xwalk/xHal_Rpi5CarSequenceTestConfig.yml button-event
./build-rpi/xSequenceTest --config=/etc/xwalk/xHal_Rpi5CarSequenceTestConfig.yml button-event
```

`--config` requires one YAML path and may appear once. A selector followed by explicit positional arguments
bypasses the YAML argument list.

## 5. Build

The core libraries are configured whenever `BUILD_TESTING` is `ON`. The Linux adapters, the runner, and the
`xSequenceTest` executable are configured only when `XWALK_HAL_BUILD_RPI` is set (root option `XWALK_BUILD_RPI`).
The executable is written directly to `${CMAKE_BINARY_DIR}`. Run from the `xWalk-rpi5-hw` workspace CMake project:

```sh
cmake -S . -B build-rpi -DXWALK_BUILD_RPI=ON -DBUILD_TESTING=ON
cmake --build build-rpi --target xSequenceTest --parallel
```

Build the host verification through the central selector:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --target xGoogleTest --parallel
```

## 6. Configuration

CMake copies the module manifests and YAML runtime configuration to the `config` directory of the sequence-test
build directory, and compiles the copied YAML path into the runner.

`config/xHal_Rpi5CarSequenceTestConfig.yml` (`schema_version: 1`) contains:

- `board`: `/dev/gpiochip0`, empty GPIO chip name and label, `/dev/i2c-1`, the robot configuration path
  `/tmp/xwalk-init-angles.config`, and the ALSA `default` PCM and mixer devices with mixer element `PCM`;
- `ai`: speech-provider deployment values (`piper` executable and `en_US-amy-low.onnx` model) without storing
  credentials; and
- `sequences`: the formal argument list for each selector.

The module XML files use the same suite/case schema as `xGoogleTest`. Their entries are mirrored into the aggregate
`xGoogleTest` host and hardware XML files, which perform runtime selection and strict validation. The host
manifest enables all eight cases; the hardware manifest lists seven cases (no `PiperStream`) and disables them all.

## 7. Testing

### Host verification

Run every deterministic in-memory case, or one case, through the central host selector:

```sh
./build/xGoogleTest TEST_SUITE_XWALK_SEQUENCE:1
./build/xGoogleTest TEST_SUITE_XWALK_SEQUENCE:ButtonEvent:1
./build/xGoogleTest TEST_SUITE_XWALK_SEQUENCE:InitAngles:1
./build/xGoogleTest TEST_SUITE_XWALK_SEQUENCE:RobotHat5Motor:1
./build/xGoogleTest TEST_SUITE_XWALK_SEQUENCE:ServoHat:1
./build/xGoogleTest TEST_SUITE_XWALK_SEQUENCE:Servo:1
./build/xGoogleTest TEST_SUITE_XWALK_SEQUENCE:Motor:1
./build/xGoogleTest TEST_SUITE_XWALK_SEQUENCE:PiperStream:1
./build/xGoogleTest TEST_SUITE_XWALK_SEQUENCE:Tone:1
```

The host CI job script `xWalk-rpi5-tool/shell-agent/gerrit-tool/run-host-ci-job.sh`, used by the xWalk Host
Quality workflow, explicitly selects the complete `TEST_SUITE_XWALK_SEQUENCE` host suite for its configured GCC or
Clang and Debug or Release build. This CI selection runs only deterministic core tests; it never builds or invokes
the Raspberry Pi hardware adapters.

### Hardware tests

The RPI profile registers seven direct CTest entries, each labelled `hardware;sequence`:

| CTest entry | Selector | Timeout |
| --- | --- | --- |
| `xWalkButtonEventSequenceHardwareTest` | `button-event` | 45 s |
| `xWalkInitAnglesSequenceHardwareTest` | `init-angles` | 30 s |
| `xWalkRobotHat5MotorSequenceHardwareTest` | `motor-robothat5` | 15 s |
| `xWalkMotorSequenceHardwareTest` | `motor` | 15 s |
| `xWalkServoHatSequenceHardwareTest` | `servo-hat` | 30 s |
| `xWalkServoSequenceHardwareTest` | `servo` | 15 s |
| `xWalkToneSequenceHardwareTest` | `tone` | 75 s, `DISABLED` |

List them without running:

```sh
ctest --test-dir build-rpi -N -L hardware
```

Do not execute them on an ordinary development host. Run a sequence only with explicit approval and after the
safety confirmation listed for it below. Each can be selected through the central hardware profile
(`./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_SEQUENCE:<Case>:1`) or run directly.

#### Button event sequence

The `button-event` selection ports `robot-hat/tests/button_event_test.py` to the C++ GPIO abstraction. It claims
Robot HAT D0 (GPIO17) as a pull-up input and prints timestamped `Pressed` and `Released` events through one
combined-edge registration with ten-millisecond debounce.

The Python script installs falling and rising handlers sequentially, causing the second registration to replace
the first. The port uses the script's commented combined-edge form so both intended events remain observable. Its
infinite sleep loop is replaced by a required duration from 1 to 3600 seconds.

After confirming the Raspberry Pi, Robot HAT, button wiring, and GPIO device, run it for 30 seconds:

```sh
./build-rpi/xSequenceTest button-event 30 /dev/gpiochip0 "" ""
./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_SEQUENCE:ButtonEvent:1
```

It opens the GPIO character device and claims physical GPIO17.

#### Initialization-angle sequence

The `init-angles` selection ports `robot-hat/tests/init_angles_test.py`. It resets the Robot HAT MCU, waits the
additional ten milliseconds from the Python script, and initializes PWM channels 10, 11, and 12 to `10`, `45`, and
`-45` degrees in registration order.

The Python call passes `3` as the positional `db` argument. The C++ port uses an explicit writable configuration
path instead and writes zero calibration offsets before initialization so the requested physical angles are
deterministic.

After confirming power, mechanical clearance, servo connections, PWM channels, and the correct Raspberry Pi and
Robot HAT:

```sh
./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_SEQUENCE:InitAngles:1
./build-rpi/xSequenceTest init-angles /dev/i2c-1 /dev/gpiochip0 "" "" ./build-rpi/init-angles.config
```

This operation resets the MCU and moves three servos.

#### Robot HAT v5 motor sequence

The `motor-robothat5` selection ports `robot-hat/tests/motor_robothat5_test.py`. Four dual-PWM motors use channel
pairs `12/13`, `14/15`, `16/17`, and `18/19`. Each bounded cycle applies `-50%` for one second, `+50%` for one
second, and then stops every motor.

The upstream infinite loop is replaced with a required cycle count from 1 to 100. Normal completion and exceptions
both make an independent non-throwing stop attempt on all four motors. Normal completion preserves the final
100 ms delay from the Python `finally` block.

After confirming Robot HAT v5, motor wiring, external motor power, mechanical clearance, and a safe raised-wheel
setup, run one cycle:

```sh
./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_SEQUENCE:RobotHat5Motor:1
./build-rpi/xSequenceTest motor-robothat5 1 /dev/i2c-1
```

#### Servo HAT sequence

The `servo-hat` selection ports `robot-hat/tests/servo_hat_test.py`. It resets the Robot HAT MCU, preserves the
script's additional one-second delay, and then visits PWM channels zero through 15 in order. Each servo moves to
`10` degrees, waits 100 ms, moves to `0` degrees, and waits another 100 ms.

After the sweep, ADC channels zero through four are read and reported in order. The upstream infinite monitor is
replaced by a required sample count from 1 to 3600; every sample retains the original one-second delay.

After confirming Robot HAT power, mechanical clearance, safe servo linkages, all PWM connections, and the correct
Raspberry Pi devices, take one ADC sample:

```sh
./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_SEQUENCE:ServoHat:1
./build-rpi/xSequenceTest servo-hat 1 /dev/i2c-1 /dev/gpiochip0 "" ""
```

This sequence resets the MCU and moves servos.

#### Servo sequence

The `servo` selection ports `robot-hat/tests/servo_test.py`. It creates servos for PWM channels zero through 11,
moves each channel sequentially to `-20` degrees with a 100 ms delay after every command, and then repeats the
ordered sweep at `+20` degrees.

The upstream infinite loop is replaced with a required complete-cycle count from 1 to 100. Normal completion
leaves all 12 servos at `+20` degrees, matching the final phase of the original loop.

After confirming Robot HAT power, PWM connections, mechanical clearance, and safe servo linkages, run one cycle:

```sh
./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_SEQUENCE:Servo:1
./build-rpi/xSequenceTest servo 1 /dev/i2c-1
```

#### Robot HAT motor sequence

The `motor` selection ports `robot-hat/tests/motor_test.py`. It preserves the original PWM-plus-direction wiring:
the first motor uses P13 with D4, and the second uses P12 with D5. Each bounded cycle applies `-50%` to both
motors for one second, applies `+50%` for one second, and then stops both motors.

The upstream infinite loop is replaced with a required cycle count from 1 to 100. Normal completion and exceptions
both make an independent non-throwing stop attempt on each motor, followed by the original final 100 ms delay.

After confirming the correct Robot HAT revision, P13/D4 and P12/D5 wiring, external motor power, mechanical
clearance, and a safe raised-wheel setup, run one cycle:

```sh
./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_SEQUENCE:Motor:1
./build-rpi/xSequenceTest motor 1 /dev/i2c-1 /dev/gpiochip0 "" ""
```

#### Piper stream comparison

The host-only `PiperStream` case ports `robot-hat/tests/test_piper_stream.py`. It preserves the `en_US-amy-low`
model, exact speech text, status-message order, and separately timed requests with streaming enabled and disabled.
The provider, monotonic clock, and output are injected so the case runs deterministically without synthesizing or
playing audio.

The upstream Piper implementation comes from the external Python `sunfounder_voice_assistant` package. This
workspace currently has no C++ Piper provider exposing both streamed and buffered modes, so no physical
`xSequenceTest` selector or hardware XML entry is registered. The existing Espeak provider is intentionally not
substituted because doing so would not test Piper or the requested stream-mode distinction.

#### Tone sequence

The `Tone` case ports the enabled portion of `robot-hat/tests/tone_test.py`. It preserves the 72-note order across
measures 1 through 17, an 80-percent volume request, and a tempo of 60 quarter-note beats per minute. The
commented Baby Shark experiment is not executable source behavior and is intentionally not included. The host
case generates and validates PCM but does not open an audio device.

The hardware case is disabled in both hardware XML manifests and its direct CTest entry is disabled. After
confirming the correct Raspberry Pi, Robot HAT, speaker, ALSA devices, and a safe playback environment, it can be
selected explicitly:

```sh
./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_SEQUENCE:Tone:1
./build-rpi/xSequenceTest tone default default PCM
```

The physical sequence produces approximately 48 seconds of audio at the source-compatible 80-percent mixer
setting. Use different explicit PCM, mixer, and mixer-element names when the platform does not use ALSA `default`
and `PCM`.

## 8. Dependencies

- HAL libraries: `xWalkGpio`, `xWalkBoardControl`, `xWalkRobot`, `xWalkMotor`, `xWalkAdc`, `xWalkServo`,
  `xWalkMusic`, `xWalkTrace`, and `xWalkLibraryCommon`.
- RPI profile: `xWalkGpioLinux`, `xWalkI2cLinux`, `xWalkMusicAlsa`, and yaml-cpp.
- [`xGoogleTest`](../xGoogleTest/xGoogleTest.md) for host execution and hardware-profile dispatch.

## 9. Safety and constraints

- Every sequence is bounded; the runner validates counts and durations against their documented ranges.
- Hardware sequences reset the MCU, move servos and motors, claim GPIO lines, or play audio. All hardware XML
  entries are disabled by default, and none may be run without explicit approval and a confirmed safe Raspberry
  Pi and Robot HAT setup.
- Motor sequences make independent non-throwing stop attempts on normal completion and on exceptions.
- The YAML configuration stores no credentials.

## 10. Related notes

- [xWalkHal](../../xWalkHal.md)
- [xGoogleTest](../xGoogleTest/xGoogleTest.md)
- [xExample](../xExample/xExample.md)
- [xWalkHal Layer1](../../layer1/xWalkHal%20Layer1.md)

---

[Previous page](../xGoogleTest/xGoogleTest.md) · [Chapter index](../../../../index.md) · [Next page](../../device/xWalkHal%20Device%20Layer.md)
