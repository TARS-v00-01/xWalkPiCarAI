<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkPwm

**2. xWalk hardware &middot; Module 59**

<!-- xwalk-page-header:end -->

# xWalkPwm

C++17 Robot HAT PWM channel and shared-timer control for the xWalk Firmware HAL. `XWalkPwm` drives one of 20
Robot HAT PWM channels over I2C and shares timer periods through `XWalkPwmTimerState`.

## 1. Overview

The module receives an `XWalkI2c` object instead of opening Raspberry Pi hardware directly. This permits host
testing with callback-driven I2C data and optional Raspberry Pi access through the Linux `i2c-dev` backend.

The non-virtual `XWalkI2c` type is provided by the sibling `xWalkI2c` module. An application or test entry
point creates the backend, the I2C interface, and the shared timer-state objects, then passes the I2C and
timer-state objects by reference to PWM. `XWalkPwm` stores non-owning pointers to both dependencies and does not
own or construct them. Shared standard-library headers are provided by the sibling header-only
`xWalkLibraryCommon` interface target through `xHal_Rpi5CarCommon.h`.

A hardware composition root follows this pattern:

```cpp
xwalk::hal::XWalkI2cLinux backend;
xwalk::hal::XWalkI2c i2c(
    &backend,
    XHAL_I2C_PROBE_CALLBACK(xwalk::hal::XWalkI2cLinux),
    XHAL_I2C_WRITE_REGISTER_CALLBACK(xwalk::hal::XWalkI2cLinux),
    XHAL_I2C_READ_CALLBACK(xwalk::hal::XWalkI2cLinux),
    nullptr,
    XHAL_I2C_TRY_WRITE_REGISTER_CALLBACK(xwalk::hal::XWalkI2cLinux));
xwalk::hal::XWalkPwmTimerState timerState;
xwalk::hal::XWalkPwm pwm(i2c, 0U, {}, timerState);
```

Declaration order expresses lifetime: `pwm` is destroyed first, followed by `timerState`, `i2c`, and finally
`backend`.

Ordinary output methods keep their exception-based validation and failure reporting.
`trySetPulseWidthPercent()` is the separate non-throwing actuator cleanup path: it validates without throwing,
uses the I2C safe-write callback, and returns whether the complete output update succeeded.

Ported behavior:

| PWM contract | C++ implementation |
|---|---|
| Channels `0..19` or `P0..P19` | Integer and string constructors |
| Addresses `0x14`, `0x15`, `0x16` | Probed in the same order |
| Seven shared PWM timer periods | `XWalkPwmTimerState` |
| Channel register base `0x20` | Preserved |
| Register groups `0x40/0x44` and `0x50/0x54` | Preserved |
| 72 MHz timer calculation | Preserved |
| Default 50 Hz initialization | Preserved |
| High-byte then low-byte register data | Explicit in `write16()` |

Invalid seven-bit I2C addresses, frequencies, percentages, and register values are rejected with C++
exceptions. Non-finite floating-point arguments report `std::invalid_argument`; finite values outside a
supported numeric range report `std::out_of_range`.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkPwm`

Source directory

## 3. Directory layout

```text
xWalkPwm/
├── CMakeLists.txt                                Library, host-test, and hardware-test targets
├── include/
│   ├── xHal_Rpi5CarPwm.h                         Public XWalkPwm class
│   └── xHal_Rpi5CarPwmTimerState.h               Shared, mutex-protected timer periods
├── src/
│   ├── xHal_Rpi5CarPwm.cpp                       Channel parsing, timer mapping, and I2C address selection
│   ├── xHal_Rpi5CarPwmLifecycle.cpp              PWM constructors, destructor, and initial 50 Hz setup
│   ├── xHal_Rpi5CarPwmTimer.cpp                  Frequency search, prescaler, period, and shared timer state
│   ├── xHal_Rpi5CarPwmTimerState.cpp             Thread-safe access to private shared timer periods
│   ├── xHal_Rpi5CarPwmTimerStateLifecycle.cpp    Timer-state constructor and destructor
│   └── xHal_Rpi5CarPwmOutput.cpp                 Pulse width, percentage conversion, and 16-bit register output
├── simulation/                                   Standalone host simulation with an in-memory I2C backend
└── test/
    ├── hardware/src/xHal_Rpi5CarPwmHardwareTest.cpp  Channel 0 zero-output hardware test
    ├── include/
    │   ├── xHal_Rpi5CarPwmTestFunctions.h        Test scenario declarations
    │   └── xHal_Rpi5CarPwmTestI2c.h              Callback-based fake I2C declarations
    └── src/
        ├── xHal_Rpi5CarPwmTestMain.cpp           Selector dispatch and trace arguments
        ├── xHal_Rpi5CarPwmTestI2c.cpp            Fake I2C callbacks
        ├── xHal_Rpi5CarPwmTestI2cLifecycle.cpp   Fake I2C lifecycle
        ├── xHal_Rpi5CarPwmTestAddress.cpp        Address and channel scenarios
        ├── xHal_Rpi5CarPwmTestOutput.cpp         Register-data and percentage scenarios
        ├── xHal_Rpi5CarPwmTestTimer.cpp          Timer-mapping and frequency scenarios
        ├── xHal_Rpi5CarPwmTestValidation.cpp     Invalid-input scenarios
        └── xHal_Rpi5CarPwmTestTrace.cpp          Persistent trace-selector scenarios
```

The fake I2C sources are also compiled into the device-group interaction test.

## 4. Child modules

- [xWalkPwm Simulation](simulation/xWalkPwm%20Simulation.md) - standalone host simulation and trace selection.

## 5. Public interface

Headers: `xHal_Rpi5CarPwm.h`
and
`xHal_Rpi5CarPwmTimerState.h`.

| Member | Behavior |
|---|---|
| `XWalkPwm(XWalkI2c&, uint32 channel, optionaluint8 address, XWalkPwmTimerState&)` | Numeric channel |
| `XWalkPwm(XWalkI2c&, stringview channel, optionaluint8 address, XWalkPwmTimerState&)` | `P0` through `P19` |
| `setFrequency(float64 frequencyHz)` | Searches a prescaler and period for the channel timer |
| `setPrescaler(float64)`, `setPeriod(float64)` | Write timer registers and update shared periods |
| `setPulseWidth(float64)`, `setPulseWidthPercent(float64)` | Write the 16-bit channel output |
| `trySetPulseWidthPercent(float64) noexcept` | Non-throwing fail-safe output; returns success |
| `timerForChannel(uint32)`, `parseChannel(stringview)` | Static mapping helpers |
| `address()`, `channel()`, `timerIndex()`, `prescaler()` | Return the selected configuration |
| `period()`, `pulseWidth()`, `frequency()`, `pulseWidthPercent()` | Return the current output state |
| `XWalkPwmTimerState::updatePeriod`, `getPeriod` | Thread-safe access to the seven timer periods |

Neither class is copyable nor movable. An empty `address` probes `0x14`, `0x15`, and `0x16` in order.

## 6. Build

The library target is `xWalkPwm`, a static C++17 library linked publicly to `xWalkLibraryCommon` and `xWalkI2c`
and privately to `xWalkTrace`. The workspace root adds it with `add_subdirectory(xWalkHal/device/xWalkPwm)`.

| CMake flag | Default | Purpose |
|---|---:|---|
| `XWALK_PWM_BUILD_HOST_TESTS` | `OFF` | Build the seven hardware-independent PWM tests |
| `XWALK_PWM_BUILD_HARDWARE_TESTS` | `OFF` | Build the Linux I2C backend and RPi PWM test |
| `XWALK_I2C_BUILD_HOST_TESTS` | Inherited | Follows the PWM host-test option |
| `XWALK_I2C_BUILD_HARDWARE_TESTS` | Inherited | Follows the PWM hardware-test option |

The hardware flags are safety gates. Enabling the PWM hardware flag builds the Linux I2C backend, its
address-probe test, and a PWM zero-output test. The configuration is rejected on non-Linux systems.

When `xWalkPwm` is configured as the top-level module, specify only its test flags. CMake passes the matching
values to `xWalkI2c` automatically. When `xWalkI2c` is configured directly, its own flags remain independent and
default to `OFF`.

## 7. Configuration

Host tests generate `generated/xWalkPwmTrace.xml` in the build tree with
`simulation/config/xHal_Rpi5CarPwmTraceConfig.py`, preserving previously stored trace states. The host-test
trace log is `log/xWalkPwmTest.log` in the module build tree.

## 8. Testing

Host mode is a logic simulation. It uses the fake callback-based I2C object and does not open `/dev/i2c-1` or
require an RPi or Robot HAT. The inherited I2C host-test option still compiles the `xWalkI2cLinux` library for
the I2C suite. Use a separate build directory so CMake cannot reuse hardware-mode cache values. Run the
following commands from the repository root.

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkPwm -B xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-host -DXWALK_PWM_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-host --output-on-failure
```

List the separately registered PWM and I2C tests without running them:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-host -N
```

Every entry has label `host`:

| CTest name | Selector | PWM functionality |
|---|---|---|
| `xWalkPwmAddressTest` | `address` | Address probing, channel parsing, and timer selection |
| `xWalkPwmTimerMappingTest` | `mapping` | Mapping of all 20 channels to seven timers |
| `xWalkPwmRegisterDataTest` | `register` | Big-endian 16-bit register data |
| `xWalkPwmPercentageTest` | `percentage` | Shared period and pulse-width percentage conversion |
| `xWalkPwmFrequencyTest` | `frequency` | Default 50 Hz timer configuration |
| `xWalkPwmValidationTest` | `validation` | Invalid channel, frequency, and output values |
| `xWalkPwmTraceSelectionTest` | `trace` | Persistent trace-selector parsing and application |
| `xWalkI2cHostTest` | - | Callback-based host I2C behavior |

Use the exact CTest name with `-R` to run one registered test. Anchoring the regular expression with `^` and `$`
prevents similarly named tests from being selected accidentally:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-host -R '^xWalkPwmFrequencyTest$' --output-on-failure
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-host -R '^xWalkI2cHostTest$' --output-on-failure
```

The PWM executable also accepts a selector from the table when invoked directly. Without a selector it runs all
PWM scenarios in one process:

```bash
./xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-host/xWalkPwmTest frequency
```

CTest is preferred for normal use because it reports the selected test name, execution status, and failure
output consistently.

### Hardware compilation without execution

The hardware targets can be compile-checked on a Linux host before the RPi and Robot HAT are connected:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkPwm -B xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-rpi -DXWALK_PWM_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-rpi -N -L hardware
```

The PWM flag automatically enables the matching I2C hardware flag. The listed hardware tests are:

| CTest name | Hardware action |
|---|---|
| `xWalkI2cLinuxHardwareProbeTest` | Open `/dev/i2c-1` and probe `0x14`, `0x15`, and `0x16` |
| `xWalkPwmHardwareZeroOutputTest` | Initialize PWM channel 0 and write a zero pulse width |

The backend and tests compile on Linux but still require physical hardware validation. Execute them only after
explicit approval, on a confirmed safe Raspberry Pi and Robot HAT setup with the vehicle safely raised or the
motors disconnected:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-rpi -L hardware --output-on-failure
```

During the first physical test, confirm the 16-bit byte order with an I2C logic analyzer capture against the
documented register protocol.

### Clean the build

Clean host-test outputs while retaining the configured CMake cache:

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-host --target clean
```

Remove the host or hardware build directory for a completely clean configuration:

```bash
cmake -E remove_directory xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-host
```

```bash
cmake -E remove_directory xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/build-rpi
```

These commands do not remove the `xWalkPwm`, `xWalkI2c`, or `xWalkLibraryCommon` source directories. Repeat the
three host commands above for a clean rebuild.

## 9. Dependencies

- `xWalkLibraryCommon` - header-only interface target with fixed-width types and Robot HAT PWM constants.
- `xWalkI2c` - callback-based I2C abstraction; `xWalkI2cLinux` for hardware tests.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.

Consumers include `xWalkServo`, `xWalkMotor`, `xWalkBuzzer`, and `xWalkLed`.

## 10. Safety and constraints

- The caller owns the `XWalkI2c` and `XWalkPwmTimerState` objects; both must outlive every `XWalkPwm`.
- PWM objects on the same Robot HAT must share one `XWalkPwmTimerState`, because channels on one timer share its
  period.
- `trySetPulseWidthPercent()` writes through the I2C safe-write callback and is the intended cleanup path.
- Hardware tests write to the Robot HAT. Never run them without explicit approval and a confirmed safe setup.

## 11. Related notes

- [xWalkPwm Simulation](simulation/xWalkPwm%20Simulation.md)
- [xWalkHal Device Layer](../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../test/xWalkHal%20Device%20Tests.md)
- [xWalkI2c](../../interface/xWalkI2c/xWalkI2c.md)
- [xWalkServo](../xWalkServo/xWalkServo.md)
- [xWalkMotor](../../sensor/xWalkMotor/xWalkMotor.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)

---

[Previous page](../test/xWalkHal%20Device%20Tests.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkPwm%20Simulation.md)
