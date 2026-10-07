<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkBuzzer

**2. xWalk hardware &middot; Module 102**

<!-- xwalk-page-header:end -->

# xWalkBuzzer

C++17 active and passive buzzer control for the xWalk Firmware HAL. The module controls active buzzers through
GPIO and passive buzzers through PWM; passive buzzers additionally support frequency and duration-based playback.

## 1. Overview

The application creates either a PWM object for a passive buzzer or a GPIO object for an active buzzer. The
selected object is passed by reference, stored as a non-owning pointer, and must outlive the buzzer controller.

```cpp
XWalkHal::XWalkPwm buzzerPwm(i2c, 0U, XHAL_RPI5CAR_I2C_ADDRESS_1, timerState);
XWalkHal::XWalkBuzzer passiveBuzzer(buzzerPwm);

XWalkHal::XWalkGpio buzzerGpio(&backend, callbacks, "D4");
XWalkHal::XWalkBuzzer activeBuzzer(buzzerGpio);
```

Construction immediately requests the inactive state. Destruction does not perform hardware I/O and contains no
trace operations.

Ported behavior:

- Passive-buzzer activation uses a 50 percent PWM duty cycle.
- Passive-buzzer deactivation uses a zero percent PWM duty cycle.
- Active buzzers use logical GPIO `on()` and `off()` operations.
- Passive frequency selection is expressed in Hertz.
- Playback without a duration remains active until `off()` is called.
- Finite playback divides the duration into equal sounding and silent halves.
- Frequency and playback operations are rejected for active buzzers.
- Non-finite, negative, and unrepresentable durations are rejected before output.

The GPIO object's configured logical polarity determines the physical active level. `XWalkBuzzer` does not
duplicate or override that polarity setting.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer`

Source directory

## 3. Directory layout

```text
xWalkBuzzer/
├── CMakeLists.txt                                   Library, host-test, and hardware-test targets
├── include/xHal_Rpi5CarBuzzer.h                     Public API and non-owning dependency contracts
├── src/
│   ├── xHal_Rpi5CarBuzzer.cpp                       Output, frequency, validation, and playback behavior
│   └── xHal_Rpi5CarBuzzerLifecycle.cpp              Dependency binding and initial inactive state
├── simulation/                                      Silent GPIO and I2C backend, trace configuration, executable
└── test/
    ├── hardware/src/xHal_Rpi5CarBuzzerHardwareTest.cpp  PWM channel 0 inactive-state hardware test
    ├── include/xHal_Rpi5CarBuzzerTestSupport.h      Named GPIO and I2C callbacks shared by Buzzer host tests
    └── src/
        ├── xHal_Rpi5CarBuzzerTest.cpp               In-memory PWM and GPIO behavior coverage
        └── xHal_Rpi5CarBuzzerTestSupport.cpp        Test-support callback implementations
```

The test-support source is also compiled into the sensor-group interaction test.

## 4. Child modules

- [xWalkBuzzer Simulation](simulation/xWalkBuzzer%20Simulation.md) - device-free simulation over real GPIO, I2C,
  PWM, active-buzzer, and passive-buzzer interfaces.

## 5. Public interface

Header: `xHal_Rpi5CarBuzzer.h`
in the module `include` directory.

| Declaration | Behavior |
|---|---|
| `explicit XWalkBuzzer(XWalkPwm& pwm)` | Passive buzzer; requests the inactive state |
| `explicit XWalkBuzzer(XWalkGpio& gpio)` | Active buzzer; requests the inactive state |
| `void on()`, `void off()` | 50 or 0 percent duty cycle, or logical GPIO on or off |
| `void setFrequency(float64 frequencyHz)` | Passive only; sets the PWM frequency in Hertz |
| `void play(float64 frequencyHz)` | Passive only; sounds until `off()` |
| `void play(float64 frequencyHz, float64 durationSeconds)` | Passive; half the duration on, half off |
| `boolean isOn() const noexcept`, `boolean isPassive() const noexcept` | Report the state and buzzer kind |

The class is neither copyable nor movable.

## 6. Build

The library target is `xWalkBuzzer`, a static C++17 library linked publicly to `xWalkLibraryCommon`, `xWalkPwm`,
and `xWalkGpio` and privately to `xWalkTrace`. The workspace root adds it with
`add_subdirectory(xWalkHal/sensor/xWalkBuzzer)`.

| CMake option | Default | Effect |
|---|---|---|
| `XWALK_BUZZER_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkBuzzerTest`; also enables PWM, I2C, and GPIO host tests |
| `XWALK_BUZZER_BUILD_HARDWARE_TESTS` | `OFF` | Builds `xWalkBuzzerHardwareTest`; requires Linux device APIs |

## 7. Configuration

The module uses unique `RPI` trace identifiers for ordinary Buzzer operations. Enabled messages are written to
the terminal and the configured log file. A selector such as `RPI.283.enable` updates the generated XML
catalogue; later runs load that state without requiring the selector again. Host tests generate
`generated/xWalkBuzzerTrace.xml` in the build tree with `simulation/config/xHal_Rpi5CarBuzzerTraceConfig.py`.

## 8. Testing

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/build-host -DXWALK_BUZZER_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/build-host --output-on-failure
```

The host configuration runs the Buzzer, PWM, I2C, and GPIO suites without accessing physical devices.
`xWalkBuzzerHostTest` (label `host`) covers passive control and playback, active control, duration validation,
and trace selection.

Hardware compilation and test discovery:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/build-rpi -DXWALK_BUZZER_BUILD_HARDWARE_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/sensor/xWalkBuzzer/build-rpi -N -L hardware
```

These commands compile and list `xWalkBuzzerHardwareInactiveTest` and the dependency hardware tests without
executing them.

## 9. Dependencies

- `xWalkPwm` - passive-buzzer output; transitively `xWalkI2c`.
- `xWalkGpio` - active-buzzer output.
- `xWalkLibraryCommon` - fixed-width types and Robot HAT constants.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.

## 10. Safety and constraints

- The caller owns the PWM or GPIO dependency, which must outlive the buzzer.
- Finite playback blocks the caller for the requested duration.
- Running the buzzer hardware executable accesses `/dev/i2c-1` and changes PWM channel zero. Run it only with
  explicit approval on a confirmed safe Raspberry Pi and Robot HAT setup.

## 11. Related notes

- [xWalkHal Sensor Layer](../xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Sensor Tests](../test/xWalkHal%20Sensor%20Tests.md)
- [xWalkPwm](../../device/xWalkPwm/xWalkPwm.md)
- [xWalkGpio](../../interface/xWalkGpio/xWalkGpio.md)

---

[Previous page](../xWalkHal%20Sensor%20Layer.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkBuzzer%20Simulation.md)
