<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkHal Interface
Tests

**2. xWalk hardware &middot; Module 75**

<!-- xwalk-page-header:end -->

# xWalkHal Interface Tests

`xWalkInterfaceGroupTest` is the group interaction test of the HAL interface layer. It complements the
individual module tests by checking that configuration values flow correctly into the I2C, SPI, GPIO, audio,
utility, and language-model interfaces, and that failures stop dependent initialization.

## 1. Overview

All operating-system, audio, model, and hardware operations use deterministic in-memory callbacks. The test
does not access physical devices or services. Configuration files are written to a `test-data` directory
under the test binary directory (`XWALK_INTERFACE_GROUP_TEST_DATA_DIRECTORY`).

- `ConfigurationInitializesBusAndDigitalInterfaces`: `XWalkConfig` values drive an I2C probe and read, an SPI
  transfer, a named GPIO `D2` output, and `XWalkUtils::mapping`.
- `InvalidOrFailedInitializationStopsLaterInterfaces`: invalid configuration claims no interface, a failed I2C
  probe prevents later SPI and GPIO use, and an invalid mapping range throws.
- `AudioConfigurationFlowsToInjectedAlsaBoundary`: audio settings reach the injected ALSA operations through
  stream open, write, recovery, volume, and close; a configure failure closes the PCM handle.
- `LanguageModelConfigurationAndBackendResultsPropagate`: instructions and message limits reach the backend;
  empty responses and backend failures propagate to the caller.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/test` -
source directory

## 3. Directory layout

```text
test/
    CMakeLists.txt                                  xWalkInterfaceGroupTest target and CTest registration
    include/xHal_Rpi5CarInterfaceGroupTestSupport.h I2C, SPI, and GPIO recording fakes and callbacks
    src/xHal_Rpi5CarInterfaceGroupTest.cpp          Group test cases
    src/xHal_Rpi5CarInterfaceGroupTestSupport.cpp   Fake callback implementations
```

The support header uses the named namespace `xwalk::hal::test::interface_group`. The target also compiles the
audio and language-model test-support sources from
`../xWalkAudio/hardware/test/src` and `../xWalkLanguageModel/test/src` and reuses their headers.

## 4. Build

The workspace build adds this directory only when the host profile is active (`BUILD_TESTING=ON` and
`XWALK_BUILD_RPI=OFF`). From the repository root:

```bash
cmake -S xWalk-rpi5-hw -B build-host/group-tests -DBUILD_TESTING=ON -DXWALK_BUILD_RPI=OFF -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-host/group-tests --target xWalkInterfaceGroupTest --parallel
```

The executable can also be run directly:

```bash
build-host/group-tests/xWalkHal/interface/test/xWalkInterfaceGroupTest
```

## 5. Testing

The CTest entry `xWalkInterfaceGroupTest` carries the labels `host`, `interface-group`, and `group-tests`:

```bash
ctest --test-dir build-host/group-tests -L interface-group --output-on-failure
```

This directory defines no hardware test.

## 6. Dependencies

- GoogleTest (`GTest::gtest_main`) and the system gmock library and headers.
- `xWalkAudioAlsa`, `xWalkConfig`, `xWalkGpio`, `xWalkI2c`, `xWalkLanguageModel`, `xWalkSpi`, `xWalkUtils`,
  and `xWalkTrace`.

## 7. Related notes

- [xWalkHal Interface Layer](../xWalkHal%20Interface%20Layer.md)
- [xWalkAudio](../xWalkAudio/xWalkAudio.md)
- [xWalkConfig](../xWalkConfig/xWalkConfig.md)
- [xWalkGpio](../xWalkGpio/xWalkGpio.md)
- [xWalkI2c](../xWalkI2c/xWalkI2c.md)
- [xWalkLanguageModel](../xWalkLanguageModel/xWalkLanguageModel.md)
- [xWalkSpi](../xWalkSpi/xWalkSpi.md)
- [xWalkUtils](../xWalkUtils/xWalkUtils.md)

---

[Previous page](../xWalkGpio/test/xWalkGpio%20Tests.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkI2c/xWalkI2c.md)
