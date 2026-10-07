<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkLed

**2. xWalk hardware &middot; Module 105**

<!-- xwalk-page-header:end -->

# xWalkLed

C++17 single-color and RGB LED control for the xWalk Firmware HAL. The combined module provides a GPIO-backed
single-color LED with background blinking and a three-channel PWM RGB LED with common-terminal polarity support.

## 1. Overview

The compatibility target name `xWalkRgbLed` aliases the combined `xWalkLed` library, while configuration and
testing use only the `XWALK_LED_*` options.

### Single-color LED

The application creates and configures the GPIO object, then passes it by reference. `XWalkLed` stores a
non-owning pointer, so the GPIO must outlive the LED controller and its blink worker.

```cpp
XWalkHal::XWalkGpio ledGpio(&backend, callbacks, "LED");
XWalkHal::XWalkLed led(ledGpio);
```

The controller owns only its worker thread. `close()` stops blinking and requests the inactive output but does
not release the caller-owned GPIO.

- `on()`, `off()`, and `toggle()` logical output operations.
- Existing blinking stopped before direct output operations.
- Configurable complete blink cycles, transition delay, and inactive pause.
- Repeated sequences until `stopBlinking()` or another output command.
- Worker stop checks at most every 10 milliseconds during configured delays.
- Normal worker shutdown leaves the LED logically inactive.
- Worker hardware operations must not throw; a violation terminates the process.
- Destruction joins a remaining worker without releasing the GPIO.

The GPIO object's logical polarity determines the physical active level. Transition delays shorter than
10 milliseconds use the polling interval to avoid an unbounded busy loop. Calls that mutate an `XWalkLed` must
come from one controlling execution context. Its atomic state accessors may be read while the worker runs.

### RGB LED

The application creates the I2C interface, shared PWM timer state, and three PWM objects before constructing
`XWalkRgbLed`. All three PWM objects must outlive the RGB controller.

```cpp
XWalkHal::XWalkPwm red(i2c, 0U, XHAL_RPI5CAR_I2C_ADDRESS_1, timerState);
XWalkHal::XWalkPwm green(i2c, 1U, XHAL_RPI5CAR_I2C_ADDRESS_1, timerState);
XWalkHal::XWalkPwm blue(i2c, 2U, XHAL_RPI5CAR_I2C_ADDRESS_1, timerState);
XWalkHal::XWalkRgbLed rgbLed(red, green, blue, XWalkHal::XWalkRgbLedCommon::Anode);
```

- Fixed component arrays ordered red, green, and blue, from 0 to 255.
- Packed colors encoded as `0xRRGGBB`.
- Six-digit hexadecimal text with optional surrounding `#` removal.
- Common-anode inversion before PWM percentage conversion.
- Common-cathode active-high output without inversion.
- Common-anode mode as the default.
- Invalid common modes, packed values, and hexadecimal text rejected.

RGB PWM writes are sequential. If a later output throws, an earlier physical channel may already be updated; the
stored logical color changes only after all three writes succeed.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed`

Source directory

## 3. Directory layout

```text
xWalkLed/
├── CMakeLists.txt                                   Library, alias, host-test, and hardware-test targets
├── include/
│   ├── xHal_Rpi5CarLed.h                            Single-color LED API, worker state, and GPIO ownership
│   ├── xHal_Rpi5CarRgbLed.h                         RGB LED API and three non-owning PWM dependencies
│   └── xHal_Rpi5CarRgbLedTypes.h                    Common-terminal enumeration and fixed RGB color type
├── src/
│   ├── xHal_Rpi5CarLed.cpp                          Direct output, blinking, and worker control
│   ├── xHal_Rpi5CarLedLifecycle.cpp                 Single-color LED initialization and worker cleanup
│   ├── xHal_Rpi5CarRgbLed.cpp                       Color decoding, polarity conversion, and PWM output
│   └── xHal_Rpi5CarRgbLedLifecycle.cpp              RGB PWM binding and common-mode validation
├── simulation/                                      Device-free GPIO and I2C backend, trace configuration
└── test/
    ├── hardware/src/
    │   ├── xHal_Rpi5CarLedHardwareTest.cpp          LED GPIO inactive-state test
    │   └── xHal_Rpi5CarRgbLedHardwareTest.cpp       RGB PWM channels 0 to 2 output test
    ├── include/xHal_Rpi5CarLedTestSupport.h         Named GPIO and I2C callback state shared by LED host tests
    └── src/
        ├── xHal_Rpi5CarLedTest.cpp                  GPIO LED timing, validation, and failure coverage
        ├── xHal_Rpi5CarLedTestSupport.cpp           Test-support callback implementations
        └── xHal_Rpi5CarRgbLedTest.cpp               RGB decoding, polarity, output, and validation coverage
```

## 4. Child modules

- [xWalkLed Simulation](simulation/xWalkLed%20Simulation.md) - device-free simulation over real GPIO, I2C, PWM,
  LED, and RGB LED interfaces.

## 5. Public interface

Headers live in the module `include`
directory.

| Declaration | Behavior |
|---|---|
| `explicit XWalkLed(XWalkGpio& gpio)` | Binds the caller-owned GPIO |
| `on()`, `off()`, `toggle()` | Stop blinking, then set the logical output |
| `blink(uint32 cycleCount, float64 toggleDelaySeconds, float64 pauseSeconds)` | Starts the blink worker |
| `stopBlinking()`, `close()` | Join the worker; `close()` also requests the inactive output |
| `isOn()`, `isBlinking()` | Atomic state accessors |
| `XWalkRgbLed(XWalkPwm& red, XWalkPwm& green, XWalkPwm& blue, XWalkRgbLedCommon = Anode)` | RGB binding |
| `setColor(const rgbcolor&)`, `setColor(uint32)`, `setColor(stringview)` | Array, `0xRRGGBB`, or hex text |
| `color()`, `common()` | Return the stored color and common-terminal mode |

Both classes are neither copyable nor movable.

## 6. Build

The library target is `xWalkLed` with the alias `xWalkRgbLed`, a static C++17 library linked publicly to
`xWalkLibraryCommon`, `xWalkGpio`, and `xWalkPwm` and privately to `xWalkTrace`. The workspace root adds it with
`add_subdirectory(xWalkHal/sensor/xWalkLed)`.

| CMake option | Default | Effect |
|---|---|---|
| `XWALK_LED_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkLedTestSupport`, `xWalkLedTest`, and `xWalkRgbLedTest` |
| `XWALK_LED_BUILD_HARDWARE_TESTS` | `OFF` | Builds both hardware executables; requires the Linux GPIO API |

Both options also propagate to the GPIO and PWM test options.

## 7. Configuration

The module uses unique `RPI` trace identifiers for ordinary LED operations. Enabled messages are written to the
terminal and the configured log file. A selector such as `RPI.268.enable` updates the generated XML catalogue;
later runs load that state without requiring the selector again. The destructor and `noexcept` blink worker
contain no trace operations. Host tests generate `generated/xWalkLedTrace.xml` with
`simulation/config/xHal_Rpi5CarLedTraceConfig.py`.

## 8. Testing

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/build-host -DXWALK_LED_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/build-host --output-on-failure
```

The host configuration runs `xWalkLedHostTest` and `xWalkRgbLedHostTest` (label `host`) and their GPIO, PWM, and
I2C dependency suites without accessing physical devices.

Hardware compilation and test discovery:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/build-rpi -DXWALK_LED_BUILD_HARDWARE_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/sensor/xWalkLed/build-rpi -N -L hardware
```

These commands compile and list `xWalkLedHardwareInactiveTest`, `xWalkRgbLedHardwareOutputTest`, and the
dependency hardware tests without executing them.

## 9. Dependencies

- `xWalkGpio` - single-color LED output.
- `xWalkPwm` - RGB channel output; transitively `xWalkI2c`.
- `xWalkLibraryCommon` - fixed-width types, threading aliases, and RGB constants.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.

## 10. Safety and constraints

- The caller owns the GPIO and the three PWM objects; each must outlive its controller.
- An RGB write failure can leave the physical channels partially updated.
- The hardware executables access `/dev/gpiochip0` or `/dev/i2c-1` and change outputs. Run them only with
  explicit approval on a confirmed safe Raspberry Pi and Robot HAT setup.

## 11. Related notes

- [xWalkHal Sensor Layer](../xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Sensor Tests](../test/xWalkHal%20Sensor%20Tests.md)
- [xWalkPwm](../../device/xWalkPwm/xWalkPwm.md)
- [xWalkGpio](../../interface/xWalkGpio/xWalkGpio.md)

---

[Previous page](../test/xWalkHal%20Sensor%20Tests.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkLed%20Simulation.md)
