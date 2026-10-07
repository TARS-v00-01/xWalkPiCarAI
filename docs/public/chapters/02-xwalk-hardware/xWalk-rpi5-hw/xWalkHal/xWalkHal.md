<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [2. xWalk hardware](../../index.md) / xWalkHal

**2. xWalk hardware &middot; Module 47**

<!-- xwalk-page-header:end -->

# xWalkHal

`xWalkHal` is the C++17 hardware abstraction layer of the xWalk PiCar-X firmware. It groups the Robot HAT
interface, device, sensor, and Layer 1 service libraries, a host-only Robot HAT simulator, and the central
HAL test and example executables. The workspace CMake project in `xWalk-rpi5-hw` builds every HAL library
and registers the tests contributed by each module.

## 1. Overview

The HAL modules are organized by responsibility while retaining their existing library targets, namespaces,
APIs, tests, and trace identifiers:

- `interface` contains low-level platform interfaces and common services.
- `device` contains hardware device abstractions.
- `sensor` contains sensor and actuator components.
- `layer1` contains higher-level robot services and features.

Dependencies flow from `interface` through `device` and `sensor` to `layer1`. A higher group may use a lower
group when its existing contract requires it. The repository-wide `xWalk-rpi5-hw/xWalkLibrary/common` interface
remains outside `xWalkHal` because HAL, Agent, Controller, IW, and Trace consumers share it.

The `xWalkHal` directory has no aggregate `CMakeLists.txt`. The workspace project
`xWalk-rpi5-hw/CMakeLists.txt` adds every HAL module with
`add_subdirectory`, derives the HAL host or Raspberry Pi mode, propagates it to every module, and defines the
`xWalkHal` interface library (alias `xWalk::Hal`) that links all HAL libraries.

Each architectural group has a hardware-independent GoogleTest interaction suite. These suites complement, and
do not replace, each module's individual host tests.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal` (source directory)

## 3. Directory layout

```text
xWalk-rpi5-hw/xWalkHal/
├── interface/                  Low-level platform interfaces and common services
│   ├── test/                   Interface-group interaction suite
│   ├── xWalkAudio/             Shared ALSA PCM and mixer ownership
│   ├── xWalkConfig/            Section and store configuration persistence
│   ├── xWalkGpio/              GPIO lines, polarity, and interrupts
│   ├── xWalkI2c/               Callback-based I2C access
│   ├── xWalkLanguageModel/     Language-model coordinator and Ollama provider
│   ├── xWalkSpi/               Bounded SPI transfers
│   ├── xWalkUtils/             Injected Linux utilities
│   └── xWalkWebSearch/         Bounded loopback SearXNG search client
├── device/                     Hardware device abstractions
│   ├── test/                   Device-group interaction suite
│   └── xWalkAdc, xWalkAdxl345, xWalkCamera, xWalkPwm, xWalkServo, xWalkUltrasonic, xWalkUserButton
├── sensor/                     Sensor and actuator components
│   ├── test/                   Sensor-group interaction suite
│   └── xWalkBuzzer, xWalkLed, xWalkLineTracker, xWalkMotor
├── layer1/                     Higher-level robot services and features
│   ├── test/                   Layer 1 group interaction suite
│   └── xWalkBoardControl, xWalkGPT, xWalkMusic, xWalkRobot, xWalkSpeaker, xWalkVoiceAssistant
├── simulation/
│   └── xWalkRobotHat/          Host-only deterministic Robot HAT simulator
└── xWalkTest/
    ├── xExample/               Ported hardware and service example launcher
    ├── xGoogleTest/            Central GoogleTest executable and XML test profiles
    └── xSequenceTest/          Cross-module button, servo, ADC, motor, speech, and tone flows
```

## 4. Child modules

| Note | Description |
|---|---|
| [xWalkHal Interface Layer](interface/xWalkHal%20Interface%20Layer.md) | Low-level interfaces and services |
| [xWalkHal Device Layer](device/xWalkHal%20Device%20Layer.md) | Hardware device abstractions |
| [xWalkHal Sensor Layer](sensor/xWalkHal%20Sensor%20Layer.md) | Sensor and actuator components |
| [xWalkHal Layer1](layer1/xWalkHal%20Layer1.md) | Higher-level robot services and features |
| [xWalkRobotHat](simulation/xWalkRobotHat/xWalkRobotHat.md) | Deterministic host-only Robot HAT simulator |
| [xExample](xWalkTest/xExample/xExample.md) | Ported hardware and service example launcher |
| [xGoogleTest](xWalkTest/xGoogleTest/xGoogleTest.md) | Central HAL GoogleTest runner and XML profiles |
| [xSequenceTest](xWalkTest/xSequenceTest/xSequenceTest.md) | Cross-module sequence scenarios |

## 5. Public interface

Each HAL module exports its public headers from its own `include` directory and links them through its static
library target. The workspace `xWalkHal` interface target aggregates `xWalkAdc`, `xWalkAdxl345`, `xWalkAudio`,
`xWalkBoardControl`, `xWalkBuzzer`, `xWalkCamera`, `xWalkLibraryCommon`, `xWalkConfig`, `xWalkGpio`, `xWalkGPT`,
`xWalkI2c`, `xWalkIW`, `xWalkLanguageModel`, `xWalkWebSearch`, `xWalkLed`, `xWalkLineTracker`, `xWalkMotor`,
`xWalkMusic`, `xWalkPwm`, `xWalkRobot`, `xWalkServo`, `xWalkSpeaker`, `xWalkSpi`, `xWalkTrace`,
`xWalkUltrasonic`, `xWalkUserButton`, `xWalkUtils`, and `xWalkVoiceAssistant`. In a Raspberry Pi build it also
links the Linux, ALSA, Ollama, Vosk, Espeak, and Pico2Wave backend libraries.

## 6. Build

Run every command in this section from the `xWalk-rpi5-hw` directory, which contains the workspace
`CMakeLists.txt` and `CMakePresets.json`. Host and Raspberry Pi verification must use separate build
directories because they enable different backends and tests; the workspace configuration rejects a build
that enables both.

| Workspace flag | Default | Result |
|---|---:|---|
| `BUILD_TESTING` | `ON` | Builds deterministic host tests when `XWALK_BUILD_RPI=OFF` |
| `XWALK_BUILD_RPI` | `OFF` | Builds Raspberry Pi backends and hardware-labelled tests |
| `XWALK_BUILD_ALL_BACKENDS` | `OFF` | Compiles every Linux provider without selecting hardware execution |
| `XWALK_ENABLE_PACKAGING` | `OFF` | Enables CPack Debian packaging; requires `XWALK_BUILD_RPI=ON` |

The workspace sets `XWALK_HAL_BUILD_HOST` and `XWALK_HAL_BUILD_RPI` and forces every per-module option, such as
`XWALK_PWM_BUILD_HOST_TESTS` or `XWALK_I2C_BUILD_HARDWARE_TESTS`, from that mode. Individual module options are
not needed for a workspace build. When central tests are enabled, per-module host tests are collected by the
single `xGoogleTest` executable instead of separate module executables.

Configure and build the complete host build:

```bash
cmake -S . -B build-host -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build-host --parallel
```

The `host-debug` preset is an equivalent configuration whose binary directory is `../build-host/cmake`:

```bash
cmake --preset host-debug
```

Configure and compile the Raspberry Pi backends and hardware tests on Linux without running them:

```bash
cmake -S . -B build-rpi -DXWALK_BUILD_RPI=ON -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build-rpi --parallel
```

Compilation on an Ubuntu host validates the Linux backend code but does not validate a physical Robot HAT.

Clean compiled outputs while retaining the host configuration, or remove a complete build configuration:

```bash
cmake --build build-host --target clean
cmake -E remove_directory build-host
cmake -E remove_directory build-rpi
```

## 7. Configuration

A Raspberry Pi configuration reads device defaults from
`rpi-defaults.conf` and generates the
runtime configuration through
`generate-rpi-runtime.sh`.
Speech, music, and camera provider options such as `XWALK_GPT_BUILD_VOSK_PROVIDER`,
`XWALK_MUSIC_BUILD_ALSA_BACKEND`, and `XWALK_CAMERA_BUILD_OPENCV_BACKEND` follow the HAL Raspberry Pi mode. Central
host tests force the ALSA, I2C, GPIO, SPI, utility, and Ollama backends on because they exercise them through
injected callbacks.

The project-managed Vosk assets are documented in [xWalkLibrary](../xWalkLibrary/xWalkLibrary.md). The xExample
CMake configuration writes their absolute paths into its build-local YAML, so Vosk selectors do not depend on
`/usr/share`, the dynamic-linker search path, or the current working directory. CMake selects the separate Linux
ARM64 or x86-64 native library for the target. Neither retained library supports 32-bit Raspberry Pi OS.

## 8. Testing

Host mode is deterministic logic simulation. It must not open GPIO, I2C, SPI, or Audio devices, and it does not
require a Raspberry Pi or Robot HAT.

List and run every registered host test:

```bash
ctest --test-dir build-host -N -L host
ctest --test-dir build-host -L host --output-on-failure --parallel 4
```

Plain `ctest --test-dir build-host --output-on-failure` is equivalent in a host-only build, but the `host` label
makes the intended test class explicit.

The HAL scenarios are registered inside the single `xGoogleTest` CTest entry (labels `host;unit`); their sources
remain in each owning module. The executable is written to the top of the build directory and can be run
directly. Use the central runtime suite name to select one HAL module, or one exact case:

```bash
./build-host/xGoogleTest
./build-host/xGoogleTest --gtest_list_tests
./build-host/xGoogleTest TEST_SUITE_XWALK_PWM:1
./build-host/xGoogleTest TEST_SUITE_XWALK_PWM:Frequency:1
./build-host/xGoogleTest --gtest_filter=TEST_SUITE_XWALK_SERVO.*
```

The XML inventory and `--gtest_list_tests` output are the current sources of truth when cases are added. See
[xGoogleTest](xWalkTest/xGoogleTest/xGoogleTest.md) for the separate host and hardware XML profiles, the source
inventory, and runtime selection.

| Submodule | Central suite | Test scope |
|---|---|---|
| xWalkAdc | `TEST_SUITE_XWALK_ADC` | ADC conversion, in-memory I2C simulation, and trace persistence |
| xWalkAdxl345 | `TEST_SUITE_XWALK_ADXL345` | Accelerometer conversion, safe simulation, and trace persistence |
| xWalkAudio | `TEST_SUITE_XWALK_AUDIO` | Injected ALSA ownership, host simulation, and recovery behavior |
| xWalkBoardControl | `TEST_SUITE_XWALK_BOARD_CONTROL` | Board services, safe simulation, and trace persistence |
| xWalkBuzzer | `TEST_SUITE_XWALK_BUZZER` | Active/passive behavior, safe simulation, and trace persistence |
| xWalkCamera | `TEST_SUITE_XWALK_CAMERA` | Still/stream capture validation, safe simulation, and traces |
| xWalkConfig | `TEST_SUITE_XWALK_CONFIG` | Section/store persistence, trace selectors, and safe simulation |
| xWalkGpio | `TEST_SUITE_XWALK_GPIO` | Linux-backend GPIO simulation, pin mapping, polarity, and interrupts |
| xWalkGPT | `TEST_SUITE_XWALK_GPT` | Speech coordination, safe simulation, and trace persistence |
| xWalkI2c | `TEST_SUITE_XWALK_I2C` | Callback-based I2C behavior |
| xWalkLanguageModel | `TEST_SUITE_XWALK_LANGUAGE_MODEL` | Coordinator, simulation, trace selectors, fake HTTP |
| xWalkLed | `TEST_SUITE_XWALK_LED` | Single/RGB LED behavior, safe simulation, and trace persistence |
| xWalkLineTracker | `TEST_SUITE_XWALK_LINE_TRACKER` | Tracking, in-memory simulation, and trace persistence |
| xWalkMotor | `TEST_SUITE_XWALK_MOTOR` | Motor control, safe simulation, and trace persistence |
| xWalkMusic | `TEST_SUITE_XWALK_MUSIC` | Music behavior, silent simulation, trace persistence, ALSA adapter |
| xWalkPwm | `TEST_SUITE_XWALK_PWM` | Addressing, timers, output, safe simulation, and trace persistence |
| xWalkRobot | `TEST_SUITE_XWALK_ROBOT` | Multi-servo coordination, safe simulation, and trace persistence |
| xWalkServo | `TEST_SUITE_XWALK_SERVO` | Angle, pulse output, in-memory simulation, and trace persistence |
| xWalkSpeaker | `TEST_SUITE_XWALK_SPEAKER` | Speaker tasks, silent simulation, traces, ALSA adaptation |
| xWalkSpi | `TEST_SUITE_XWALK_SPI` | Linux-backend SPI simulation and bounded transfer behavior |
| xWalkTrace | `TEST_SUITE_XWALK_TRACE` | Trace behavior |
| xWalkUltrasonic | `TEST_SUITE_XWALK_ULTRASONIC` | Distance, in-memory GPIO simulation, and trace persistence |
| xWalkUserButton | `TEST_SUITE_XWALK_USER_BUTTON` | Button events, safe simulation, and trace persistence |
| xWalkUtils | `TEST_SUITE_XWALK_UTILS` | Injected utilities, safe Linux behavior, and host simulation |
| xWalkVoiceAssistant | `TEST_SUITE_XWALK_VOICE_ASSISTANT` | Coordinator, simulation, backend composition |
| Simulation arguments | `TEST_SUITE_XWALK_SIMULATION` | Shared simulation trace-argument boundaries |
| xSequenceTest | `TEST_SUITE_XWALK_SEQUENCE` | Button, servo, ADC, motor, speech, and tone flows |
| xExample | Direct `xExample <selector> <arguments>` invocation | Ported hardware and service examples |

Upstream examples are ported one by one under `xWalkTest/xExample`. That module has separate reusable and
Raspberry Pi layers and one central `main.cpp`. It is an example launcher rather than a test suite, so it has no
XML profile or CTest registration, and it is built only in the Raspberry Pi mode. See
[xExample](xWalkTest/xExample/xExample.md) for each selector's YAML configuration and argument form.

The group interaction suites, the Robot HAT simulator tests, and the xWalk-rpi5-iw schema validator and
xWalkController tests are separate CTest entries and run through the complete `ctest` command.

| Goal | Command |
|---|---|
| Show verbose host output | `ctest --test-dir build-host -L host --verbose` |
| Rerun only previous failures | `ctest --test-dir build-host --rerun-failed --output-on-failure` |
| Run one exact test | `ctest --test-dir build-host -R '^TEST_NAME$' --output-on-failure` |
| Run one submodule directory | `ctest --test-dir build-host/SUBMODULE --output-on-failure` |
| List hardware tests without running | `ctest --test-dir build-rpi -N -L hardware` |

Hardware tests are opt-in. List them without running:

```bash
ctest --test-dir build-rpi -N -L hardware
```

Do not run hardware-labelled tests on a development host. Run them only when the user explicitly requests it and
confirms that the intended Raspberry Pi and Robot HAT are connected and safe: Robot HAT wiring, channel
assignments, actuator power, mechanical clearance, and the safe initial state must be verified first, and the
selected module note must be reviewed. Under those conditions the complete suite, or one module directory, runs
with:

```bash
ctest --test-dir build-rpi -L hardware --output-on-failure
ctest --test-dir build-rpi/xWalkHal/interface/xWalkI2c -L hardware --output-on-failure
```

## 9. Dependencies

| Requirement | Purpose |
|---|---|
| CMake 3.16 or newer (3.25 for presets) | Configures the workspace project |
| C++17 compiler | Builds all native libraries and tests |
| ALSA development library | Builds the optional shared PCM and mixer backend |
| libcurl development library | Builds the Ollama, web-search, and example HTTP clients |
| OpenCV development library | Builds camera streaming and the camera host suites |
| libsndfile development library | Builds compressed-audio decoding |
| Protobuf and gRPC development libraries | Build the xWalk-rpi5-iw interface library |
| GoogleTest and GoogleMock development libraries | Provide the HAL host-test framework and group suites |
| json-c development library | Parses runtime trace configuration files |
| TinyXML2 development library | Validates the central test selection file |
| yaml-cpp development library | Loads board, AI, example, and hardware runtime values |
| Python 3 interpreter | Generates trace catalogues and runs workspace host checks |
| `xWalk-rpi5-hw/xWalkLibrary` | Architecture-selected portable dependencies and shared Vosk model |
| `xWalk-rpi5-iw` | Protobuf and gRPC interface module imported by the workspace |
| `xWalk-rpi5-trace` | Trace macros, metadata, and persistent trace configuration |
| `xWalk-rpi5-hw/xWalkController` | Standalone CLI aggregate included by host and RPI workspace builds |
| `xWalk-rpi5-tool/shell-agent/env-tool/dtoverlays` | Robot HAT and Servo HAT+ Raspberry Pi boot overlays |
| Linux GPIO, I2C, and SPI UAPI headers | Required when `XWALK_BUILD_RPI=ON` |

On Debian or Ubuntu, install the normal build dependencies with:

```bash
sudo apt-get install build-essential cmake libasound2-dev libcurl4-openssl-dev libgrpc++-dev libprotobuf-dev libgtest-dev libjson-c-dev libtinyxml2-dev libyaml-cpp-dev libsndfile1-dev linux-libc-dev
```

The workspace-level `xWalkLibrary/common` module is a header-only interface library shared by HAL, agent, and
other application layers. It does not register a separate executable test.

## 10. Safety and constraints

- Host builds never open GPIO, I2C, SPI, camera, or audio devices.
- Hardware tests may move motors or servos, drive GPIO or PWM outputs, sound a buzzer, illuminate LEDs, or wait
  for sensor or button activity.
- Before deploying to a Raspberry Pi, follow the overlay installation and verification instructions in
  xWalk-rpi5-tool. The overlay files are boot resources and are not
  part of the C++ build.
- Trace identifiers remain unique within the `RPI` tag; the workspace metadata validator rejects duplicates.

| Message | Cause | Resolution |
|---|---|---|
| Missing libsndfile development files | Native audio headers or library are absent | Install `libsndfile1-dev` |
| `xWalkController` does not exist | The standalone CLI aggregate is missing | Restore `xWalkController` |
| Host and RPI verification require separate build directories | Both modes were enabled | Use separate builds |
| Linux UAPI check fails | Linux development headers are missing | Install `linux-libc-dev` |
| `No tests were found` | Verification flags are `OFF` | Enable the appropriate workspace flag |

## 11. Related notes

- [xWalk-rpi5-hw](../xWalk-rpi5-hw.md)
- [xWalkLibrary](../xWalkLibrary/xWalkLibrary.md)
- [xWalkLibrary Common](../xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalkDriver](../xWalkDriver/xWalkDriver.md)
- [xWalkController](../xWalkController/xWalkController.md)
- [xWalk-rpi5-iw](../../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md)
- [xWalk-rpi5-trace](../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)
- xWalk-rpi5-tool

---

[Previous page](../xWalkDriver/xWalkVoice/xWalkVoicePromptCar/xWalkVoicePromptCar.md) · [Chapter index](../../index.md) · [Next page](xWalkTest/xExample/xExample.md)
