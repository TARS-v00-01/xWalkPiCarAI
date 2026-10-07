<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xGoogleTest

**2. xWalk hardware &middot; Module 49**

<!-- xwalk-page-header:end -->

# xGoogleTest

`xGoogleTest` is the single GoogleTest selector for xWalk HAL host and physical hardware verification. It compiles
host test sources from their owning module directories, registers them under exact suite and case names, and, in
the Raspberry Pi profile, dispatches the existing module hardware executables. No module test is copied into this
directory.

## 1. Overview

The three runner files under `src/` implement configuration, selection, and the central process entry point. A
fourth host-only source, `xHal_Rpi5CarSimulationArgumentsTest.cpp`, provides the shared simulation trace-argument
boundary cases.

Most pre-existing HAL tests use `assert`-based standalone entry points rather than native `TEST` or `TEST_F`
declarations. CMake compiles each such source as an object library with its `main` symbol renamed through
`main=<entry point>`, and `TestRunner` registers those scenarios dynamically. The I2C and SPI host simulations of
the Linux backends are registered directly as native GoogleTest cases. Each legacy scenario executes in an
isolated child process so one failure cannot stop the remaining cases.

Two XML profiles control selection:

- the host profile, `config/test_config.xml`, enables every host-safe case by default; and
- the hardware profile, `config/hardware_test_config.xml`, disables every physical case by default.

Board and AI runtime values for hardware dispatch are kept separately in
`config/xHal_Rpi5CarGoogleTestConfig.yml`.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/xWalkTest/xGoogleTest` —
source directory

## 3. Directory layout

```text
xGoogleTest/
├── CMakeLists.txt                              Central executable, legacy object targets, CTest entry
├── config/
│   ├── test_config.xml                         Host suite/case selection, enabled by default
│   ├── hardware_test_config.xml                Hardware suite/case selection, disabled by default
│   └── xHal_Rpi5CarGoogleTestConfig.yml        Board, AI, and formal hardware-test arguments
├── include/
│   ├── TestConfig.hpp                          XML selection loader and validator
│   ├── TestRunner.hpp                          Suite registration and selection contract
│   └── TestRunnerTypes.h                       Runner record types
└── src/
    ├── main.cpp                                Process entry point and executable-directory resolution
    ├── TestConfig.cpp                          Strict XML parsing and inventory checks
    ├── TestRunner.cpp                          Registration, runtime selection, child-process execution
    └── xHal_Rpi5CarSimulationArgumentsTest.cpp Host-only simulation trace-argument cases
```

## 4. Public interface

`xGoogleTest` is an executable, not a library. Its command-line interface is:

| Argument | Meaning |
| --- | --- |
| `<SUITE>:<0\|1>` | Enable or disable a complete suite for this process only |
| `<SUITE>:<CASE>:<0\|1>` | Enable or disable one case for this process only |
| `--test-profile=hardware` | Use the hardware XML profile (RPI builds only); may appear once |
| `--runtime-config=<yaml>` or `--runtime-config <yaml>` | Replace the default runtime YAML; may appear once |
| Standard GoogleTest flags | For example `--gtest_list_tests`, `--gtest_filter`, `--gtest_repeat` |

If at least one custom entry is enabled, the enabled custom entries form an allowlist and custom disables are
then applied. If all custom entries are disables, the XML selection is used as the starting set. Unknown suites,
unknown cases, and malformed values produce an error, print the complete valid inventory, and return a non-zero
status.

Filter precedence is custom runtime selection, then an explicit `--gtest_filter`, then the XML configuration.
Runtime selections never edit either XML file.

## 5. Build

The host test build requires the GoogleTest, json-c, TinyXML2, and yaml-cpp development packages; the camera suite
also requires OpenCV (`core`, `imgcodecs`, `videoio`) and the HTTP cancellation regression requires a Python 3
interpreter. On Debian or Ubuntu:

```sh
sudo apt-get install libgtest-dev libjson-c-dev libtinyxml2-dev libyaml-cpp-dev
```

The target is configured when `BUILD_TESTING` is `ON` in either the host or the Raspberry Pi HAL profile. With
`BUILD_TESTING=OFF`, this target and its external test dependencies are not configured. Run the commands from the
`xWalk-rpi5-hw` workspace CMake project:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --parallel
```

The executable is always written directly to `${CMAKE_BINARY_DIR}`. CMake copies both XML configurations and the
configured runtime YAML file to `${CMAKE_BINARY_DIR}`. The runner resolves that directory from `/proc/self/exe`, so
execution does not depend on the current working directory or on configuration-path preprocessor definitions.

When embedded in the full Node build, the runner resolves HAL fixtures below `hardware/xWalkHal` beside its
executable. Standalone hardware builds retain `xWalkHal`. CMake supplies the relative directory through
`XWALK_GOOGLE_TEST_HAL_BINARY_SUBDIRECTORY`, so the runner does not assume that the hardware product is the
top-level project.

Configure and compile the hardware profile without executing hardware:

```sh
cmake -S . -B build-rpi -DXWALK_BUILD_RPI=ON -DBUILD_TESTING=ON
cmake --build build-rpi --target xGoogleTest --parallel
```

In the RPI profile, `xGoogleTest` depends on every module hardware test executable and on `xSequenceTest`, and
receives each executable path through an `XWALK_HARDWARE_*_TEST` compile definition.

## 6. Configuration

### XML selection

`config/test_config.xml` contains 27 host suites and 86 host-safe cases, all enabled.
`config/hardware_test_config.xml` contains 22 hardware suites and 32 physical cases, all disabled. A suite and each
child case must have an exact registered name and an `enabled` value of `0` or `1`. The loader rejects malformed
XML, missing or unknown entries, duplicate suites or cases, and invalid attributes before any test runs.

The suite inventory maps to these owning source locations below `xWalk-rpi5-hw/xWalkHal` unless noted:

| Suite | Owning test source directory |
| --- | --- |
| `TEST_SUITE_XWALK_SIMULATION` | `xWalkTest/xGoogleTest/src` (host only) |
| `TEST_SUITE_XWALK_I2C` | `interface/xWalkI2c/test` |
| `TEST_SUITE_XWALK_SPI` | `interface/xWalkSpi/test` |
| `TEST_SUITE_XWALK_GPIO` | `interface/xWalkGpio/test` |
| `TEST_SUITE_XWALK_AUDIO` | `interface/xWalkAudio/hardware/test` |
| `TEST_SUITE_XWALK_CONFIG` | `interface/xWalkConfig/test` |
| `TEST_SUITE_XWALK_TRACE` | `xWalk-rpi5-trace/test` (outside `xWalk-rpi5-hw`) |
| `TEST_SUITE_XWALK_UTILS` | `interface/xWalkUtils/test`, `interface/xWalkUtils/hardware/test` |
| `TEST_SUITE_XWALK_LANGUAGE_MODEL` | `interface/xWalkLanguageModel/test`, `.../hardware/test` |
| `TEST_SUITE_XWALK_MUSIC` | `layer1/xWalkMusic/test`, `layer1/xWalkMusic/hardware/test` |
| `TEST_SUITE_XWALK_SPEAKER` | `layer1/xWalkSpeaker/test`, `layer1/xWalkSpeaker/hardware/test` |
| `TEST_SUITE_XWALK_PWM` | `device/xWalkPwm/test` |
| `TEST_SUITE_XWALK_ADC` | `device/xWalkAdc/test` |
| `TEST_SUITE_XWALK_SERVO` | `device/xWalkServo/test` |
| `TEST_SUITE_XWALK_ADXL345` | `device/xWalkAdxl345/test` |
| `TEST_SUITE_XWALK_LINE_TRACKER` | `sensor/xWalkLineTracker/test` |
| `TEST_SUITE_XWALK_ULTRASONIC` | `device/xWalkUltrasonic/test` |
| `TEST_SUITE_XWALK_MOTOR` | `sensor/xWalkMotor/test` |
| `TEST_SUITE_XWALK_LED` | `sensor/xWalkLed/test` |
| `TEST_SUITE_XWALK_BUZZER` | `sensor/xWalkBuzzer/test` |
| `TEST_SUITE_XWALK_CAMERA` | `device/xWalkCamera/test` |
| `TEST_SUITE_XWALK_USER_BUTTON` | `device/xWalkUserButton/test` |
| `TEST_SUITE_XWALK_BOARD_CONTROL` | `layer1/xWalkBoardControl/test` |
| `TEST_SUITE_XWALK_ROBOT` | `layer1/xWalkRobot/test` |
| `TEST_SUITE_XWALK_GPT` | `layer1/xWalkGPT/test`, `layer1/xWalkGPT/hardware/test` |
| `TEST_SUITE_XWALK_VOICE_ASSISTANT` | `layer1/xWalkVoiceAssistant/test`, `.../hardware/test` |
| `TEST_SUITE_XWALK_SEQUENCE` | `xWalkTest/xSequenceTest/core` (host); `xSequenceTest` executable (hardware) |

`TEST_SUITE_XWALK_ROBOT`, `TEST_SUITE_XWALK_LINE_TRACKER`, `TEST_SUITE_XWALK_ULTRASONIC`,
`TEST_SUITE_XWALK_CONFIG`, and `TEST_SUITE_XWALK_SIMULATION` exist only in the host profile.

Files below a module's `hardware/test` directory are included in the host build only when they are device-free
adapter tests. Tests that open physical GPIO, I2C, SPI, audio, camera, sensor, or actuator interfaces remain in
their module CMake targets and stay explicitly opt-in. The optional libsndfile decoder test remains governed by
`XWALK_MUSIC_BUILD_SNDFILE_DECODER` and is not part of the normal host suite.

### Runtime YAML

Board and AI runtime values are separate from XML test selection. They are stored in
`config/xHal_Rpi5CarGoogleTestConfig.yml` (`schema_version: 1`), copied beside `xGoogleTest`, and may be
overridden with `--runtime-config` without editing the checked-in file. The `board` mapping holds device paths
(`/dev/gpiochip0`, `/dev/i2c-1`, `/dev/spidev0.0`, camera, robot configuration, microphone, PCM, and mixer), the
`ai` mapping holds the Ollama endpoint and model, the Vosk library and model paths, and only the name of the
OpenAI credential environment variable (`OPENAI_API_KEY`).

The `hardware_tests` mapping supplies formal arguments for configurable hardware executables (camera still
capture, GPIO output, I2C probe, SPI transfer) and the full formal arguments for each `xSequenceTest` dispatch.
Consequently, a custom runtime YAML controls the board paths used by the invoked sequence. XML continues to control
which tests are enabled.

The generated default uses the target-selected ARM64 or x86-64 Vosk runtime and the shared small US English model
under `xWalk-rpi5-hw/xWalkLibrary/common/models`. Override `XWALK_VOSK_ARCHITECTURE`, `XWALK_VOSK_LIBRARY_PATH`,
or `XWALK_VOSK_MODEL_PATH` during CMake configuration for another target or deployment layout.

## 7. Testing

### Host profile

In a host build the target is registered as the CTest entry `xGoogleTest` with labels `host;unit`, a 120-second
timeout, and `RUN_SERIAL`, because its legacy trace-selection cases update shared build-tree trace metadata. The
host build also registers `xWalkLanguageModelHttpCancellationHostTest` (label `host`, 20-second timeout), a
Python-driven loopback regression for the Ollama HTTP provider.

Every enabled XML entry runs when no selection is supplied:

```sh
./build/xGoogleTest
ctest --test-dir build --output-on-failure
```

Runtime selections override the XML for that process only:

```sh
./build/xGoogleTest TEST_SUITE_XWALK_I2C:1
./build/xGoogleTest TEST_SUITE_XWALK_I2C:Probe:1
./build/xGoogleTest TEST_SUITE_XWALK_I2C:0
./build/xGoogleTest TEST_SUITE_XWALK_I2C:Probe:0
```

Standard GoogleTest flags remain available:

```sh
./build/xGoogleTest --gtest_list_tests
./build/xGoogleTest --gtest_filter=TEST_SUITE_XWALK_PWM.Address
./build/xGoogleTest --gtest_repeat=2
```

### Hardware profile

Physical cases use `config/hardware_test_config.xml`. The profile is compiled only by an RPI-enabled test build and
is not registered as the central host CTest entry. The individual module hardware executables carry the CTest
`hardware` label; list them without running them:

```sh
ctest --test-dir build-rpi -N -L hardware
```

List all hardware cases of the central selector without running them:

```sh
./build-rpi/xGoogleTest --test-profile=hardware --gtest_filter='*' --gtest_list_tests
```

Run hardware cases only with explicit approval, and only after confirming the correct Raspberry Pi, Robot HAT,
wiring, power, and mechanical clearance. Then select one suite or case, for example:

```sh
./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_I2C:1
./build-rpi/xGoogleTest --test-profile=hardware TEST_SUITE_XWALK_I2C:Probe:1
./build-rpi/xGoogleTest --test-profile=hardware --runtime-config=/etc/xwalk/xHal_Rpi5CarGoogleTestConfig.yml TEST_SUITE_XWALK_I2C:Probe:1
```

Running with only `--test-profile=hardware` executes no cases because the hardware XML defaults to disabled.
Supplying `--gtest_filter='*'` without `--gtest_list_tests` explicitly selects every physical case and must be
treated as a full hardware run.

### Adding a host case

Keep the source in the owning module test directory. Add it explicitly to `CMakeLists.txt`, register its suite and
case in `TestRunner.cpp`, and add the same exact entry to `config/test_config.xml`. Do not create `src/tests/` and
do not add a second unrenamed `main()` to the central executable.

## 8. Dependencies

- `xWalkTrace` and the HAL module libraries whose tests are aggregated, including the Linux backends
  `xWalkI2cLinux`, `xWalkSpiLinux`, and `xWalkGpioLinux` for the native host simulations.
- GoogleTest, TinyXML2, yaml-cpp, json-c (trace configuration), OpenCV, and Python 3.
- `xWalkLibrary/XWalkDependencies.cmake` and `xWalkLibrary/VoskModel.cmake` for dependency and Vosk asset
  resolution.
- In the RPI profile, every module hardware test executable and `xSequenceTest`.

## 9. Safety and constraints

- Host mode never opens GPIO, I2C, SPI, audio, or camera devices.
- Hardware cases may move motors or servos, drive GPIO or PWM outputs, sound a buzzer, record audio, or contact
  remote services. They are disabled by default and must not be run without explicit approval and a confirmed safe
  Raspberry Pi and Robot HAT setup.
- Runtime YAML stores only credential environment-variable names; secret values remain in the process environment.

## 10. Related notes

- [xWalkHal](../../xWalkHal.md)
- [xSequenceTest](../xSequenceTest/xSequenceTest.md)
- [xExample](../xExample/xExample.md)
- [xWalkHal Interface Layer](../../interface/xWalkHal%20Interface%20Layer.md)
- [xWalkHal Device Layer](../../device/xWalkHal%20Device%20Layer.md)
- [xWalkHal Sensor Layer](../../sensor/xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Layer1](../../layer1/xWalkHal%20Layer1.md)
- [xWalkLibrary](../../../xWalkLibrary/xWalkLibrary.md)
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xExample/xExample.md) · [Chapter index](../../../../index.md) · [Next page](../xSequenceTest/xSequenceTest.md)
