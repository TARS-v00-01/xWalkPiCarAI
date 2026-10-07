<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkServo

**2. xWalk hardware &middot; Module 61**

<!-- xwalk-page-header:end -->

# xWalkServo

C++17 Robot HAT servo control for the xWalk Firmware HAL. `XWalkServo` converts calibrated angles and pulse
durations into PWM counts on a caller-owned `XWalkPwm` channel.

## 1. Overview

`XWalkServo` receives a caller-created `XWalkPwm` by reference and stores a non-owning pointer to it. The
application or test entry point creates objects in dependency order, so the servo is destroyed before its PWM
dependency. Multiple caller-created servo objects can be registered by reference with `xWalkRobot` for
synchronized articulated motion and persisted calibration.

```cpp
xwalk::hal::XWalkI2cLinux backend;
xwalk::hal::XWalkI2c i2c(
    &backend,
    XHAL_I2C_PROBE_CALLBACK(xwalk::hal::XWalkI2cLinux),
    XHAL_I2C_WRITE_REGISTER_CALLBACK(xwalk::hal::XWalkI2cLinux),
    XHAL_I2C_READ_CALLBACK(xwalk::hal::XWalkI2cLinux));
xwalk::hal::XWalkPwmTimerState timerState;
xwalk::hal::XWalkPwm pwm(i2c, 0U, {}, timerState);
xwalk::hal::XWalkServo servo(pwm);
if (!servo.initialize())
{
    XWALK_HAL_ERROR(XWALK_RUNTIME, "Servo PWM initialization failed");
}
servo.setAngle(0.0);
```

Construction validates and stores the calibration but does not initialize PWM or send a position command.
`initialize()` is explicit, idempotent, and does not move the servo; it configures the shared timer without
selecting a position. `setAngle()`, `setPulseWidthTime()`, and `moveToSafePosition()` reject use before
successful initialization. Applications must request any centre or safe-position movement explicitly.

Ported behavior:

| Servo contract | C++ behavior |
|---|---|
| PWM period 4095 | Preserved |
| 50 Hz frame | Rounded prescaler 352 |
| Angles below -90 or above +90 degrees | Clamped to -90 or +90 degrees |
| Pulse duration 500 through 2500 microseconds | Preserved |
| Floating timer count | Truncated through the existing PWM conversion |
| Non-finite command | Rejected with `std::invalid_argument` |

The default reference output counts are 102 at -90 degrees, 307 at 0 degrees, and 511 at +90 degrees. Steering,
camera pan, and camera tilt may instead supply different validated minimum, centre, maximum, pulse calibration,
and inversion values. Inversion mirrors an angle around that servo's calibrated centre before applying its
mechanical clamp. The Raspberry Pi vehicle composition uses independent mechanical angle ranges: steering -30
through +30 degrees, pan -90 through +90 degrees, and tilt -35 through +65 degrees.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkServo`

Source directory

## 3. Directory layout

```text
xWalkServo/
├── CMakeLists.txt                                    Library, host-test, and hardware-test targets
├── include/xHal_Rpi5CarServo.h                       Public servo API, configuration, non-owning PWM dependency
├── src/
│   ├── xHal_Rpi5CarServo.cpp                         Calibrated angle mapping, pulse validation, count conversion
│   └── xHal_Rpi5CarServoLifecycle.cpp                Dependency binding and timer initialization
├── simulation/                                       Standalone host simulation over in-memory PWM and I2C
└── test/
    ├── hardware/src/xHal_Rpi5CarServoHardwareTest.cpp Channel 0 initialization hardware test
    ├── include/
    │   ├── xHal_Rpi5CarServoTestFunctions.h          Test scenario declarations
    │   └── xHal_Rpi5CarServoTestI2c.h                Callback-driven in-memory I2C recorder
    └── src/
        ├── xHal_Rpi5CarServoTestMain.cpp             Selector dispatch and trace arguments
        ├── xHal_Rpi5CarServoTestI2c.cpp              Recorder callbacks
        ├── xHal_Rpi5CarServoTestI2cLifecycle.cpp     Recorder lifecycle
        ├── xHal_Rpi5CarServoTestInitialization.cpp   Initialization scenarios
        ├── xHal_Rpi5CarServoTestAngle.cpp            Angle scenarios
        ├── xHal_Rpi5CarServoTestPulse.cpp            Pulse-width scenarios
        ├── xHal_Rpi5CarServoTestValidation.cpp       Invalid-input scenarios
        └── xHal_Rpi5CarServoTestTrace.cpp            Persistent trace-selector scenarios
```

## 4. Child modules

- [xWalkServo Simulation](simulation/xWalkServo%20Simulation.md) - standalone host simulation and trace
  selection.

## 5. Public interface

Header:
`xHal_Rpi5CarServo.h`

| Declaration | Behavior |
|---|---|
| `XWalkServoConfiguration` | Angle limits and centre (degrees), pulse limits and centre (us), `inverted` |
| `explicit XWalkServo(XWalkPwm&, const XWalkServoConfiguration& = {})` | Validates calibration; no PWM write |
| `boolean initialize()` | Configures the 50 Hz, 4095-count timer; idempotent; returns success |
| `boolean isInitialized() const noexcept` | Reports initialization state |
| `void setAngle(float64 angleDegrees)` | Clamps to the calibrated range and writes the truncated count |
| `void setPulseWidthTime(float64 pulseWidthUs)` | Clamps to 500 through 2500 microseconds in a 20,000 us frame |
| `void moveToSafePosition()` | Explicitly moves to the calibrated centre angle |

Default configuration: -90 to +90 degrees with centre 0, 500 to 2500 microseconds with centre 1500, not
inverted. The class is neither copyable nor movable.

## 6. Build

The library target is `xWalkServo`, a static C++17 library linked publicly to `xWalkLibraryCommon` and
`xWalkPwm` and privately to `xWalkTrace`. The workspace root adds it with
`add_subdirectory(xWalkHal/device/xWalkServo)`.

| CMake option | Default | Effect |
|---|---|---|
| `XWALK_SERVO_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkServoTest`; also enables the PWM and I2C host tests |
| `XWALK_SERVO_BUILD_HARDWARE_TESTS` | `OFF` | Builds `xWalkServoHardwareTest` and PWM and I2C hardware targets |

## 7. Configuration

Host tests generate `generated/xWalkServoTrace.xml` in the build tree with
`simulation/config/xHal_Rpi5CarServoTraceConfig.py`, preserving previously stored trace states. The host-test
trace log is `log/xWalkServoTest.log` in the module build tree.

## 8. Testing

The host suite uses callback-driven in-memory I2C recording and never opens a physical device. Run the following
commands from the repository root.

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkServo -B xWalk-rpi5-hw/xWalkHal/device/xWalkServo/build-host -DXWALK_SERVO_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkServo/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkServo/build-host --output-on-failure
```

The Servo flag also enables the PWM and I2C host dependency tests. Servo CTest entries, all labelled `host`:

| CTest name | Executable selector |
|---|---|
| `xWalkServoInitializationTest` | `initialization` |
| `xWalkServoAngleTest` | `angle` |
| `xWalkServoPulseWidthTest` | `pulse` |
| `xWalkServoValidationTest` | `validation` |
| `xWalkServoTraceSelectionTest` | `trace` |

Hardware compilation without execution:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkServo -B xWalk-rpi5-hw/xWalkHal/device/xWalkServo/build-rpi -DXWALK_SERVO_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkServo/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkServo/build-rpi -N -L hardware
```

Enabling the Servo hardware target also compile-checks PWM and Linux I2C hardware targets. The final command
lists `xWalkServoHardwareInitializationTest` and the dependency hardware tests only; it does not access
`/dev/i2c-1`.

## 9. Dependencies

- `xWalkPwm` - channel output and shared timer state; transitively `xWalkI2c`.
- `xWalkLibraryCommon` - fixed-width types and servo constants.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.

## 10. Safety and constraints

- The caller owns the `XWalkPwm`, which must outlive the servo.
- No constructor or `initialize()` call moves the servo; every movement is an explicit command.
- Do not execute hardware tests without explicit approval, a connected Robot HAT, a confirmed safe Raspberry Pi
  setup, and a mechanically safe servo setup.

## 11. Related notes

- [xWalkHal Device Layer](../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../test/xWalkHal%20Device%20Tests.md)
- [xWalkPwm](../xWalkPwm/xWalkPwm.md)
- [xWalkRobot](../../layer1/xWalkRobot/xWalkRobot.md)

---

[Previous page](../xWalkPwm/simulation/xWalkPwm%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkServo%20Simulation.md)
