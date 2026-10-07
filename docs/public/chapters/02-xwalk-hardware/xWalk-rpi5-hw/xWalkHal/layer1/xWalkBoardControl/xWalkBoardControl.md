<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkBoardControl

**2. xWalk hardware &middot; Module 88**

<!-- xwalk-page-header:end -->

# xWalkBoardControl

`xWalkBoardControl` is a C++17 embedded-oriented Robot HAT board-services module that combines board control,
Linux device-tree discovery, and firmware-version reporting in the single `xWalkBoardControl` static library.

## 1. Overview

The module retains three focused classes, each in separate headers and implementation files:

- `XWalkBoardControl` coordinates MCU reset, battery sensing, GPIO output, and speaker-power sequencing through
  caller-owned hardware dependencies.
- `XWalkDevice` discovers Robot HAT information from a Linux firmware device tree.
- `XWalkFirmwareInfo` reads the Robot HAT firmware version through injected I2C.

Production operations and host verification use trace IDs `RPI.321` through `RPI.338`. IDs remain unique within
the `RPI` tag, and the workspace metadata validator rejects any repeated numeric ID within that tag.

### Board-control behavior

- MCU reset drives the reset line (GPIO 5) low and high using bounded 10 ms intervals.
- Battery acquisition reads ADC channel A4 and applies the hardware divider ratio of 3.0.
- Speaker enable uses the board-specific active GPIO and a required prime callback with a 500 ms duration.
- Speaker disable drives the selected power-control GPIO inactive.
- No shell command is used for GPIO or audio control.

### Device-discovery behavior

- The default device-tree root is `/proc/device-tree`.
- Candidate direct-child device-tree node names must contain `hat`.
- Robot HAT v5 UUID `9daeea78-0000-076e-0032-582369ac3e02` is recognized.
- Product, vendor, identifier, version, and UUID properties are retained.
- Robot HAT v5 selects speaker GPIO 12 and motor mode 2.
- Missing supported UUIDs retain Robot HAT v4 defaults: GPIO 20 and motor mode 1.
- `refresh()` replaces prior information only after selected properties validate.

### Firmware-information behavior

- I2C address `0x14` is probed before `0x15`.
- Exactly three bytes are read from firmware register `0x05`.
- Major, minor, and patch components are represented as unsigned values.
- Firmware text uses `major.minor.patch` formatting.
- Robot HAT compatibility version `2.5.5` remains static metadata.

The hardware constants are defined in
`xHal_Rpi5CarCommon.h`.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl`
(source directory)

## 3. Directory layout

```text
xWalkBoardControl/
├── CMakeLists.txt                                  Library, host-test, and hardware-test targets
├── include/
│   ├── xHal_Rpi5CarBoardControl.h                  XWalkBoardControl API
│   ├── xHal_Rpi5CarBoardControlTypes.h             Speaker-prime callback type
│   ├── xHal_Rpi5CarDevice.h                        XWalkDevice API
│   ├── xHal_Rpi5CarDeviceTypes.h                   XWalkDeviceInformation
│   ├── xHal_Rpi5CarFirmwareInfo.h                  XWalkFirmwareInfo API
│   └── xHal_Rpi5CarFirmwareInfoTypes.h             XWalkFirmwareVersion
├── src/
│   ├── xHal_Rpi5CarBoardControl.cpp                Reset, battery, GPIO, and speaker operations
│   ├── xHal_Rpi5CarBoardControlLifecycle.cpp       Construction, validation, and speaker priming
│   ├── xHal_Rpi5CarDevice.cpp                      Device-tree parsing and board selection
│   ├── xHal_Rpi5CarDeviceLifecycle.cpp             Construction and default board configuration
│   ├── xHal_Rpi5CarFirmwareInfo.cpp                Firmware read and formatting
│   └── xHal_Rpi5CarFirmwareInfoLifecycle.cpp       Address probing and construction
├── simulation/                                     Standalone device-free simulation
│   ├── CMakeLists.txt
│   ├── config/xHal_Rpi5CarBoardControlTraceConfig.py   Persistent trace catalogue generator
│   ├── include/                                    Host stub, arguments, configuration, scenario
│   └── src/                                        main.cpp and their implementations
└── test/
    ├── include/xHal_Rpi5CarBoardControlTestSupport.h   xwalk::hal::test::boardcontrol support
    ├── src/                                        Board-control, device, and firmware host tests
    └── hardware/src/                               Opt-in hardware tests
```

## 4. Child modules

| Note | Description |
|---|---|
| [xWalkBoardControl Simulation](simulation/xWalkBoardControl%20Simulation.md) | Device-free simulation |

## 5. Public interface

The public headers are in the module
`include` directory.

- `xHal_Rpi5CarBoardControl.h` declares `XWalkBoardControl`: `resetMcu()`, `batteryVoltage()`,
  `enableSpeaker()`, `disableSpeaker()`, and `setPin()`.
- `xHal_Rpi5CarDevice.h` declares `XWalkDevice`: `refresh()`, `information()`, and `deviceTreeRoot()`.
- `xHal_Rpi5CarFirmwareInfo.h` declares `XWalkFirmwareInfo`: `read()`, `readText()`, `address()`, and the
  static `libraryVersion()`.

Create device discovery, Linux backends, GPIO interfaces, I2C, ADC, and board control in `main()`. Device
information selects the board-specific speaker GPIO before `XWalkBoardControl` is constructed. Firmware
information receives I2C by reference and stores only a non-owning pointer.

```cpp
XWalkDevice device;
const XWalkDeviceInformation& deviceInformation = device.information();
XWalkFirmwareInfo firmwareInformation(i2c);
XWalkBoardControl boardControl(mcuResetGpio, speakerEnableGpio, batteryAdc,
    &audioBackend, &primeSpeakerOutput);
```

## 6. Build

| Option | Default | Effect |
|---|---:|---|
| `XWALK_BOARD_CONTROL_BUILD_HOST_TESTS` | `OFF` | Builds host tests and the ADC, GPIO, and I2C host tests |
| `XWALK_BOARD_CONTROL_BUILD_HARDWARE_TESTS` | `OFF` | Builds hardware tests; requires Linux GPIO and I2C APIs |

In a workspace build these options are forced from the HAL mode. A standalone build adds `xWalkLibrary/common`,
`xWalk-rpi5-trace`, `xWalkAdc`, `xWalkGpio`, and `xWalkI2c` when their targets are not already defined. The
library compiles with `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion` on GCC and Clang.

## 7. Configuration

Host tests generate a persistent trace catalogue, `generated/xWalkBoardControlTrace.xml`, from the workspace
trace inventory with the simulation
trace configuration script.
A selector such as `--trace RPI.330.enable` updates that XML atomically. Later runs load the saved state without
requiring another flag. Enabled records are written to both the terminal and the configured log file through
xWalk trace macros.

## 8. Testing

Run from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl/build-host -DXWALK_BOARD_CONTROL_BUILD_HOST_TESTS=ON
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl/build-host --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl/build-host --output-on-failure
```

| CTest name | Executable | Labels |
|---|---|---|
| `xWalkBoardControlHostTest` | `xWalkBoardControlTest` | `host` |
| `xWalkDeviceHostTest` | `xWalkDeviceTest` (synthetic `test-device-tree`) | `host` |
| `xWalkFirmwareInfoHostTest` | `xWalkFirmwareInfoTest` | `host` |

Host tests use in-memory hardware backends and a synthetic device tree. They do not access physical GPIO, I2C,
audio, or `/proc/device-tree` resources. Reusable callback state and functions live in the named
`xwalk::hal::test::boardcontrol` support namespace; scenario sources contain only fixtures, assertions, and
suite entry points. In a workspace build these scenarios run in `xGoogleTest` as
`TEST_SUITE_XWALK_BOARD_CONTROL`.

Compile the hardware tests and list them without executing them:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl -B xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl/build-rpi -DXWALK_BOARD_CONTROL_BUILD_HARDWARE_TESTS=ON
cmake --build xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl/build-rpi --parallel
ctest --test-dir xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl/build-rpi -N -L hardware
```

| CTest name | Purpose |
|---|---|
| `xWalkBoardControlHardwareDisableTest` | Requests only the inactive speaker state through Linux GPIO and I2C |
| `xWalkDeviceHardwareDiscoveryTest` | Read-only device-tree discovery |
| `xWalkFirmwareInfoHardwareReadTest` | Firmware-version read through Linux I2C |

## 9. Dependencies

- Public: `xWalkAdc`, `xWalkLibraryCommon`, `xWalkGpio`, and `xWalkI2c`.
- Private: `xWalkTrace`.
- Hardware tests: `xWalkGpioLinux` and `xWalkI2cLinux`.
- Host tests: Python 3 for trace-catalogue generation.

## 10. Safety and constraints

- All injected GPIO, ADC, I2C, and callback contexts must outlive their consumers.
- Direct dependency access requires external serialization.
- MCU reset and speaker control drive physical Robot HAT lines on target hardware.
- Physical hardware tests require the correct Robot HAT safety setup and must not be run during normal
  verification. Run them only with explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 11. Related notes

- [xWalkHal Layer1](../xWalkHal%20Layer1.md)
- [xWalkHal Layer1 Tests](../test/xWalkHal%20Layer1%20Tests.md)
- [xWalkGPT](../xWalkGPT/xWalkGPT.md)
- [xWalkAdc](../../device/xWalkAdc/xWalkAdc.md)
- [xWalkGpio](../../interface/xWalkGpio/xWalkGpio.md)
- [xWalkI2c](../../interface/xWalkI2c/xWalkI2c.md)
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)
- [xWalkHal](../../xWalkHal.md)

---

[Previous page](../xWalkHal%20Layer1.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkBoardControl%20Simulation.md)
