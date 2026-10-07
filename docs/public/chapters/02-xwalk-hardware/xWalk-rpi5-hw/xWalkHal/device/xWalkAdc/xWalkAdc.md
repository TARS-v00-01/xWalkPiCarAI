<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkAdc

**2. xWalk hardware &middot; Module 52**

<!-- xwalk-page-header:end -->

# xWalkAdc

C++17 Robot HAT analog-to-digital converter module for the xWalk Firmware HAL. `XWalkAdc` reads 12-bit
samples from the Robot HAT microcontroller over I2C and converts them to volts.

## 1. Overview

`XWalkAdc` accepts a caller-created `XWalkI2c` by reference and stores a non-owning pointer. The `XWalkI2c`
object must outlive the ADC object. The module supports numeric channels 0 through 7 and the names `A0`
through `A7`. Automatic addressing probes `0x14` and then `0x15`; an explicit seven-bit address is validated and
used without probing.

`xWalkLineTracker` receives three caller-created `XWalkAdc` objects by reference and stores bounded non-owning
pointers ordered left, middle, and right.

| Hardware contract | C++ behavior |
|---|---|
| Channel 0 through 7 or A0 through A7 | Preserved with validated constructor overloads |
| Hardware channel mapping `7 - channel` | Preserved |
| Command flag `0x10` (`XHAL_RPI5CAR_ADC_READ_COMMAND`) | Preserved |
| Two-byte MSB-first sample | Preserved |
| Voltage conversion `value * 3.3 / 4095` | Preserved with named floating-point intermediates |
| No detected candidate address | Falls back to the default Robot HAT address `0x14` |

The host suite verifies that concurrent conversions on one object are atomic.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkAdc`

Source directory

## 3. Directory layout

```text
xWalkAdc/
├── CMakeLists.txt                                   Library, host-test, and hardware-test targets
├── include/xHal_Rpi5CarAdc.h                        Public XWalkAdc class
├── src/
│   ├── xHal_Rpi5CarAdc.cpp                          Sample read and voltage conversion
│   └── xHal_Rpi5CarAdcLifecycle.cpp                 Channel parsing, address selection, construction
├── simulation/                                      Standalone host simulation with an in-memory I2C backend
│   ├── config/xHal_Rpi5CarAdcTraceConfig.py         Persistent trace-catalogue generator
│   ├── include/                                     Host stub, argument parser, and path configuration
│   └── src/                                         Simulation entry point and implementation
└── test/
    ├── hardware/src/xHal_Rpi5CarAdcHardwareTest.cpp Linux i2c-dev read of channel 0
    ├── include/xHal_Rpi5CarAdcTestSupport.h          xwalk::hal::test::adc fake-backend declarations
    └── src/
        ├── xHal_Rpi5CarAdcTest.cpp                  Host test body
        └── xHal_Rpi5CarAdcTestSupport.cpp           Fake-backend callback implementations
```

Reusable test state and callbacks live in the named `xwalk::hal::test::adc` support component instead of the
test body.

## 4. Child modules

- [xWalkAdc Simulation](simulation/xWalkAdc%20Simulation.md) - standalone host simulation and trace selection.

## 5. Public interface

Header: `xHal_Rpi5CarAdc.h`

| Member | Behavior |
|---|---|
| `XWalkAdc(XWalkI2c&, uint32 channel, optionaluint8 address = {})` | Validates channel 0 through 7 |
| `XWalkAdc(XWalkI2c&, stringview channel, optionaluint8 address = {})` | Accepts `A0` through `A7` |
| `static uint8 parseChannel(stringview)` | Converts a channel name to its index |
| `uint16 read()` | Returns the raw two-byte, MSB-first sample |
| `float64 readVoltage()` | Returns `sample * 3.3 / 4095` in volts |
| `address()`, `channel()`, `command()` | Return the selected address, channel, and command byte |

The class is neither copyable nor movable.

## 6. Build

The library target is `xWalkAdc`, a static C++17 library linked publicly to `xWalkLibraryCommon` and
`xWalkI2c` and privately to `xWalkTrace`. The workspace root `xWalk-rpi5-hw/CMakeLists.txt` adds it with
`add_subdirectory(xWalkHal/device/xWalkAdc)`. A standalone configure pulls in the common library, `xWalkI2c`,
and `xWalk-rpi5-trace` when these targets are not already defined.

| CMake option | Default | Effect |
|---|---|---|
| `XWALK_ADC_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkAdcTest`; also enables the `xWalkI2c` host tests |
| `XWALK_ADC_BUILD_HARDWARE_TESTS` | `OFF` | Builds `xWalkAdcHardwareTest`; requires Linux i2c-dev |

GCC and Clang builds use `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`.

## 7. Configuration

Host tests generate `generated/xWalkAdcTrace.xml` in the build tree from the trace inventory
`generated/xwalk-traces.xml` with
`xHal_Rpi5CarAdcTraceConfig.py`.
The generator preserves previously stored enable and disable states. The host-test trace log is
`log/xWalkAdcTest.log` in the module build tree.

## 8. Testing

Host tests use in-memory callbacks and do not open a physical I2C device. They cover sample reads, address
selection, voltage conversion, validation, atomic concurrent conversions, and persistent trace selector parsing.

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkAdc -B xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/build-host -DXWALK_ADC_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/build-host -L host --output-on-failure
```

The CTest name is `xWalkAdcHostTest` with label `host`.

Hardware compilation without execution:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkAdc -B xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/build-rpi -DXWALK_ADC_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/build-rpi -N -L hardware
```

The final command lists `xWalkAdcHardwareReadTest` only. The group-level interaction suite is described in
[xWalkHal Device Tests](../test/xWalkHal%20Device%20Tests.md).

## 9. Dependencies

- `xWalkLibraryCommon` - fixed-width types, address validation, and Robot HAT ADC constants.
- `xWalkI2c` - callback-based I2C abstraction; `xWalkI2cLinux` for hardware tests.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.
- Python 3 interpreter for trace-catalogue generation in host builds.

## 10. Safety and constraints

- The caller owns the `XWalkI2c` object, which must outlive every `XWalkAdc` that references it.
- Hardware tests open `/dev/i2c-1`. Do not execute them without explicit approval, a connected Robot HAT on a
  confirmed safe Raspberry Pi setup, and an analog input within the hardware voltage range.
- Voltage conversion assumes the 3.3 V reference and a 4095-count full scale.

## 11. Related notes

- [xWalkHal Device Layer](../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../test/xWalkHal%20Device%20Tests.md)
- [xWalkI2c](../../interface/xWalkI2c/xWalkI2c.md)
- [xWalkLineTracker](../../sensor/xWalkLineTracker/xWalkLineTracker.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)

---

[Previous page](../xWalkHal%20Device%20Layer.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkAdc%20Simulation.md)
