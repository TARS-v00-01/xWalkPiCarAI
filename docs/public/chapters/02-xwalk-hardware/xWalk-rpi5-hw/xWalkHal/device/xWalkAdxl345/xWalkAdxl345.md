<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkAdxl345

**2. xWalk hardware &middot; Module 54**

<!-- xwalk-page-header:end -->

# xWalkAdxl345

C++17 ADXL345 accelerometer module for the xWalk Firmware HAL. `XWalkAdxl345` configures the accelerometer,
reads its X, Y, and Z data registers, converts little-endian signed samples, and reports acceleration in units
of standard gravity.

## 1. Overview

The application creates the I2C backend and the `XWalkI2c` callback interface before the accelerometer.
`XWalkAdxl345` stores a non-owning I2C pointer, so the I2C object must outlive it.

```cpp
XWalkHal::XWalkI2cLinux backend;
XWalkHal::XWalkI2c i2c(&backend, XHAL_I2C_PROBE_CALLBACK(XWalkHal::XWalkI2cLinux),
    XHAL_I2C_WRITE_REGISTER_CALLBACK(XWalkHal::XWalkI2cLinux),
    XHAL_I2C_READ_CALLBACK(XWalkHal::XWalkI2cLinux),
    XHAL_I2C_READ_REGISTER_CALLBACK(XWalkHal::XWalkI2cLinux));
XWalkHal::XWalkAdxl345 accelerometer(i2c);
const XWalkHal::adxl345values acceleration = accelerometer.read();
```

Ported behavior:

- Default seven-bit I2C address `0x53`.
- X, Y, and Z data registers `0x32`, `0x34`, and `0x36`.
- Data-format register `0x31` set to zero and power-control register `0x2D` set to measurement value `0x08`.
- Two-byte little-endian signed samples scaled by 256 counts per gravity.
- First sample discarded before each returned axis value to preserve the established sensor contract.
- Invalid axes, incomplete samples, invalid addresses, and missing register-read callbacks rejected.

Register reads are performed as one backend transaction. This prevents another execution context from changing
the selected device or register between the register address and the returned bytes.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345`

Source directory

## 3. Directory layout

```text
xWalkAdxl345/
├── CMakeLists.txt                                       Library, host-test, and hardware-test targets
├── include/
│   ├── xHal_Rpi5CarAdxl345.h                            Public driver API, ownership, and measurement contract
│   └── xHal_Rpi5CarAdxl345Types.h                       Axis enumeration and fixed three-axis result type
├── src/
│   ├── xHal_Rpi5CarAdxl345.cpp                          Configuration, register acquisition, signed scaling
│   └── xHal_Rpi5CarAdxl345Lifecycle.cpp                 Axis validation, register mapping, and lifecycle
├── simulation/                                          Standalone host simulation with an in-memory I2C backend
└── test/
    ├── hardware/src/xHal_Rpi5CarAdxl345HardwareTest.cpp Linux i2c-dev three-axis read
    ├── include/xHal_Rpi5CarAdxl345TestSupport.h          xwalk::hal::test::adxl345 callback declarations
    └── src/
        ├── xHal_Rpi5CarAdxl345Test.cpp                  Driver behavior, validation, and trace-selector coverage
        └── xHal_Rpi5CarAdxl345TestSupport.cpp           Reusable named in-memory I2C test callbacks
```

## 4. Child modules

- [xWalkAdxl345 Simulation](simulation/xWalkAdxl345%20Simulation.md) - standalone host simulation and trace
  selection.

## 5. Public interface

Headers:
`xHal_Rpi5CarAdxl345.h`
and
`xHal_Rpi5CarAdxl345Types.h`.

| Declaration | Behavior |
|---|---|
| `XWalkAdxl345(XWalkI2c&, uint8 address = 0x53)` | Validates the address; stores a non-owning I2C pointer |
| `float64 read(XWalkAdxl345Axis axis)` | Configures measurement and returns one axis in standard gravity |
| `adxl345values read()` | Returns X, Y, and Z in standard gravity |
| `uint8 address() const noexcept` | Returns the configured seven-bit address |
| `enum class XWalkAdxl345Axis` | `X`, `Y`, and `Z` |
| `adxl345values` | `fixedarray<float64, 3>` ordered X, Y, Z |

The class is neither copyable nor movable.

## 6. Build

The library target is `xWalkAdxl345`, a static C++17 library linked publicly to `xWalkLibraryCommon` and
`xWalkI2c` and privately to `xWalkTrace`. The workspace root adds it with
`add_subdirectory(xWalkHal/device/xWalkAdxl345)`. A standalone configure pulls in the common library,
`xWalkI2c`, and `xWalk-rpi5-trace` when these targets are not already defined.

| CMake option | Default | Effect |
|---|---|---|
| `XWALK_ADXL345_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkAdxl345Test`; also enables the `xWalkI2c` host tests |
| `XWALK_ADXL345_BUILD_HARDWARE_TESTS` | `OFF` | Builds `xWalkAdxl345HardwareTest`; requires Linux i2c-dev |

GCC and Clang builds use strict warnings including `-Wconversion` and `-Wsign-conversion`.

## 7. Configuration

Host tests generate `generated/xWalkAdxl345Trace.xml` in the build tree from the trace inventory with
`simulation/config/xHal_Rpi5CarAdxl345TraceConfig.py`, preserving previously stored trace states.

## 8. Testing

Run these commands from the repository root. The host configuration runs the ADXL345 suite and its I2C
dependency suite. It does not access a physical I2C device.

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345 -B xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/build-host -DXWALK_ADXL345_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/build-host --output-on-failure
```

The module CTest is `xWalkAdxl345HostTest` with label `host`. It covers single-axis and all-axis reads,
validation, and persistent trace-selector behavior. Reusable callback state lives in `xwalk::hal::test::adxl345`
instead of the test body.

Hardware compilation and test discovery:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345 -B xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/build-rpi -DXWALK_ADXL345_BUILD_HARDWARE_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/build-rpi -N -L hardware
```

These commands compile and list `xWalkAdxl345HardwareReadTest` without executing it.

## 9. Dependencies

- `xWalkLibraryCommon` - fixed-width types, address validation, and ADXL345 register constants.
- `xWalkI2c` - callback-based I2C abstraction, including the register-read callback; `xWalkI2cLinux` for
  hardware tests.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.

## 10. Safety and constraints

- The caller owns the `XWalkI2c` object, which must outlive the accelerometer.
- The `XWalkI2c` object must provide a register-read callback; reads without one are rejected.
- Running the hardware executable requires `/dev/i2c-1` access and an ADXL345 at `0x53`. Do not run it without
  explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 11. Related notes

- [xWalkHal Device Layer](../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../test/xWalkHal%20Device%20Tests.md)
- [xWalkI2c](../../interface/xWalkI2c/xWalkI2c.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)

---

[Previous page](../xWalkAdc/simulation/xWalkAdc%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkAdxl345%20Simulation.md)
