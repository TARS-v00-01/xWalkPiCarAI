<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkMotor

**2. xWalk hardware &middot; Module 109**

<!-- xwalk-page-header:end -->

# xWalkMotor

C++17 single and paired Robot HAT motor control for the xWalk Firmware HAL, with explicit arming, a movement
watchdog, safety inhibition, and non-throwing fail-safe shutdown.

## 1. Overview

The module contains:

- `XWalkMotor`, which controls one motor in PWM-and-direction or dual-PWM mode.
- `XWalkMotors`, which assigns two existing motors to left and right roles.
- `XWalkMotorsConfiguration`, which carries role, reversal, watchdog, and injectable-clock data without owning
  persistent storage.

All PWM, GPIO, and motor dependencies are passed by reference and stored as non-owning pointers. The
application creates dependencies in lifetime order and destroys the motor objects before their dependencies.

| Command | PWM-and-direction mode | Dual-PWM mode |
|---|---|---|
| Forward | Primary PWM at speed; GPIO high | Forward PWM at speed; reverse PWM zero |
| Reverse | Primary PWM at speed; GPIO low | Forward PWM zero; reverse PWM at speed |
| Stop | Primary PWM zero | Both PWM inputs zero |
| Brake | Not supported | Both PWM inputs at 100 percent |

Direction reversal exchanges forward and reverse without changing the requested signed speed magnitude.

| Motor contract | C++ behavior |
|---|---|
| Default PWM frequency of 100 Hertz | Preserved |
| Signed speed selects direction | Preserved |
| Absolute speed controls duty cycle | Preserved |
| Motor modes 1 and 2 | Preserved as typed constructor overloads |
| Forward, backward, left-turn, right-turn, and stop | Preserved |
| Runtime direction reversal | Preserved |
| Mode-two electrical brake | Exposed as `brake()` |
| Last requested speed | `speed()` reports the last successful command |
| Fail-safe shutdown | Destructors independently attempt every available zero-output path |
| File-backed motor IDs and reversal values | Replaced by explicit caller-owned configuration |

### Initialization and validation

Motor construction validates and binds dependencies but performs no PWM or GPIO operation. A single motor must
complete explicit, idempotent `initialize()` before speed or brake commands are accepted. Paired `arm()`
initializes both motors, establishes zero output on both sides, and remains disarmed if either initialization
fails. Shutdown before initialization is a no-op at the hardware boundary.

The C++ implementation validates speed before changing hardware. Commands must be finite and within -100.0
through 100.0 percent. Paired commands validate both values before changing either motor.

### Arming and watchdog

Paired motors start disarmed. Call `arm()` only after configuration and shutdown handling are ready. Movement and
electrically active dual-PWM braking are rejected while disarmed. Every non-zero movement or brake command starts
or refreshes a configurable watchdog deadline, 500 ms by default and at most 60,000 ms; `heartbeat()` refreshes
an active command and reports disarmed use through the ordinary exception boundary. Coordinators that must remain
non-throwing use `heartbeatSafely()` and handle its Boolean status. Expiry stops both channels and disarms the
controller. Invalid commands do not refresh the deadline.

Tests can inject a fake clock and disable the background worker, while deployment keeps the non-blocking
condition-variable worker enabled. The optional pre-thread-start callback is an injectable test boundary;
production leaves it null. It permits deterministic startup-failure coverage without exhausting process
resources or creating a thread.

The watchdog stores the last valid refresh timestamp rather than a future absolute deadline. A backward clock
discontinuity is treated as immediate expiry, while subtraction-based elapsed time remains defined for a large
forward jump. Neither discontinuity can preserve an old movement command.

### Safety inhibition

`inhibit()` latches inhibition and independently stops both motors; `arm()` cannot clear this latch.
`releaseInhibit()` is an owner-only recovery after verified clearance and completed cleanup; it establishes zero
output without arming or moving. While inhibited, `reverseInhibited()` accepts only non-positive wheel speeds
under an explicit lease from 1 through 1000 ms that `heartbeat()` cannot extend.

### Fail-safe shutdown

`stopSafely()` is the non-throwing actuator-cleanup primitive. A dual-PWM motor attempts both PWM channels even
if the first write fails, and a paired controller attempts both motors independently. `stop()` uses the same
complete attempt but reports an incomplete shutdown to ordinary callers. Motor and paired-motor destructors call
the non-throwing operation as a final lifecycle safeguard. The safe path uses explicit Boolean PWM and I2C
status operations and contains no exception-handling statement. Trace formatting and output remain outside
non-throwing fail-safe paths.

### Persistent configuration boundary

`XWalkMotors` does not open files. The application supplies `XWalkMotorsConfiguration` and may save the value
returned by `configuration()` through `XWalkConfigStore` from `xWalkConfig`. This keeps filesystem ownership
outside the module and allows deterministic host testing. The application converts persisted strings to
validated typed motor values before constructing `XWalkMotors`.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor`

Source directory

## 3. Directory layout

```text
xWalkMotor/
├── CMakeLists.txt                                   Library, host-test, and hardware-test targets
├── include/
│   ├── xHal_Rpi5CarMotor.h                          Single-motor driver modes and public API
│   └── xHal_Rpi5CarMotors.h                         Paired-motor configuration and coordinated-control API
├── src/
│   ├── xHal_Rpi5CarMotor.cpp                        Signed speed, direction, stop, reversal, and brake
│   ├── xHal_Rpi5CarMotorLifecycle.cpp               Validation, dependency binding, and PWM initialization
│   ├── xHal_Rpi5CarMotors.cpp                       Left and right role assignment and coordinated movement
│   └── xHal_Rpi5CarMotorsLifecycle.cpp              Paired validation, role binding, and lifecycle behavior
├── simulation/                                      Standalone host simulation with in-memory I2C and GPIO
└── test/
    ├── hardware/src/xHal_Rpi5CarMotorHardwareTest.cpp  PWM `P13` and direction `D4` stop test
    ├── include/xHal_Rpi5CarMotorTestSupport.h       xwalk::hal::test::motor callback declarations
    └── src/
        ├── xHal_Rpi5CarMotorTest.cpp                Host test body
        └── xHal_Rpi5CarMotorTestSupport.cpp         Named in-memory I2C and GPIO callbacks
```

The test-support source is also compiled into the sensor-group interaction test.

## 4. Child modules

- [xWalkMotor Simulation](simulation/xWalkMotor%20Simulation.md) - standalone host simulation that never moves a
  motor.

## 5. Public interface

Headers live in the module `include`
directory.

| Declaration | Behavior |
|---|---|
| `XWalkMotor(XWalkPwm&, XWalkGpio& direction, boolean reversed, float64 frequencyHz)` | PWM and direction |
| `XWalkMotor(XWalkPwm& forward, XWalkPwm& reverse, boolean reversed, float64 frequencyHz)` | Dual PWM |
| `initialize()`, `setSpeed()`, `stop()`, `stopSafely()`, `brake()` | Single-motor control |
| `setReversed()`, `speed()`, `reversed()`, `mode()`, `frequency()`, `initialized()` | Configuration and state |
| `XWalkMotors(XWalkMotor&, XWalkMotor&, const XWalkMotorsConfiguration& = {})` | Paired controller |
| `arm()`, `disarm()`, `isArmed()`, `heartbeat()`, `heartbeatSafely()`, `checkWatchdog()` | Arming and watchdog |
| `inhibit()`, `releaseInhibit()`, `reverseInhibited()`, `reversingInhibited()` | Safety inhibition |
| `setSpeed(left, right)`, `forward()`, `backward()`, `turnLeft()`, `turnRight()`, `stop()`, `brake()` | Moves |
| `setLeftMotorId()`, `setRightMotorId()`, `setLeftReversed()`, `toggleLeftReversed()` and right variants | Roles |
| `left()`, `right()`, `motor(id)`, `configuration()` | Access and persistence |

`reversed` defaults to `false` and `frequencyHz` to 100 Hz. `XWalkMotorMode` is `PwmAndDirection = 1`
(TC1508S-style) or `DualPwm = 2` (TC618S-style). Neither class is copyable nor movable.

## 6. Build

The library target is `xWalkMotor`, a static C++17 library linked publicly to `xWalkLibraryCommon`, `xWalkPwm`,
and `xWalkGpio` and privately to `xWalkTrace`. The workspace root adds it with
`add_subdirectory(xWalkHal/sensor/xWalkMotor)`.

| CMake option | Default | Effect |
|---|---|---|
| `XWALK_MOTOR_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkMotorTest`; also enables PWM, I2C, and GPIO host tests |
| `XWALK_MOTOR_BUILD_HARDWARE_TESTS` | `OFF` | Builds `xWalkMotorHardwareTest`; requires Linux I2C and GPIO |

## 7. Configuration

`XWalkMotorsConfiguration` defaults: left motor 1, right motor 2, no reversal, 500 ms watchdog, system clock,
and the watchdog worker enabled. Host tests generate `generated/xWalkMotorTrace.xml` in the build tree with
`simulation/config/xHal_Rpi5CarMotorTraceConfig.py`.

## 8. Testing

The host suite uses callback-driven I2C and GPIO simulations and does not open physical devices.

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/build-host -DXWALK_MOTOR_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/build-host --output-on-failure
```

The Motor flag also enables PWM, I2C, and GPIO host dependency tests. `xWalkMotorHostTest` (label `host`)
injects failures into individual PWM writes and verifies that later channels and the second motor still receive
zero-output attempts. Reusable callback state lives in `xwalk::hal::test::motor`.

Hardware compilation without execution:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/build-rpi -DXWALK_MOTOR_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/build-rpi -N -L hardware
```

The final command only lists `xWalkMotorHardwareStopTest` and the dependency hardware tests.

## 9. Dependencies

- `xWalkPwm` - speed outputs; transitively `xWalkI2c`.
- `xWalkGpio` - direction output in PWM-and-direction mode.
- `xWalkLibraryCommon` - fixed-width types and motor constants.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.
- `xWalkConfig` - optional application-side persistence of `XWalkMotorsConfiguration`.

## 10. Safety and constraints

- This process-local watchdog cannot stop motors after `SIGKILL`, a kernel failure, power-path failure, or a
  complete process stall. Initial physical testing therefore requires raised wheels, a reachable power cut-off,
  and preferably an independent hardware watchdog. A destructor is a final fallback, not the normal stop path.
- Do not execute hardware tests without explicit approval and unless the vehicle is raised, wheels cannot contact
  surrounding objects, power is controlled, and the Robot HAT motor-driver mode is confirmed.
- All dependencies are caller-owned and must outlive the motor objects.

## 11. Related notes

- [xWalkHal Sensor Layer](../xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Sensor Tests](../test/xWalkHal%20Sensor%20Tests.md)
- [xWalkPwm](../../device/xWalkPwm/xWalkPwm.md)
- [xWalkGpio](../../interface/xWalkGpio/xWalkGpio.md)
- [xWalkConfig](../../interface/xWalkConfig/xWalkConfig.md)

---

[Previous page](../xWalkLineTracker/simulation/xWalkLineTracker%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkMotor%20Simulation.md)
