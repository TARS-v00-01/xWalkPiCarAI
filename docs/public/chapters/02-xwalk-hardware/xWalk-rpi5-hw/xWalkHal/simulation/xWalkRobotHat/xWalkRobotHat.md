<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkRobotHat

**2. xWalk hardware &middot; Module 111**

<!-- xwalk-page-header:end -->

# xWalkRobotHat

`xWalkRobotHatSimulation` is a host-only, device-free Robot HAT simulator. It provides deterministic backends for
the production `XWalkI2c`, `XWalkGpio`, and `XWalkCamera` callback interfaces and bounded logical models of motor,
steering, battery, grayscale, ultrasonic, camera, and I2C-failure behavior.

## 1. Overview

The simulator never opens a Linux device, starts a camera process, contacts a network service, sleeps, or reads
wall-clock time. The normal Raspberry Pi build does not select it; the workspace adds it only in the HAL host mode.

`XWalkRobotHatSimulation` models the Robot HAT register space, PWM writes, eight ADC channels, conventional
A0/A1/A2 grayscale values, battery voltage on A4 (0 to 9.9 V), GPIO levels, a configured ultrasonic distance
(default 100 cm), camera availability and encoded frame sequences, and I2C address presence (default `0x14`).
Every operation receives a contiguous sequence number and deterministic logical time. Configured logical delays
advance that time without sleeping. Tests can inspect an owned event snapshot without physical timing.

Failures are injected by operation and target. An I2C-write target is the register address, an I2C read or probe
target is the device address, and a GPIO target is the Linux line offset. Camera capture uses target zero.
Failure counts are consumed deterministically, making one-channel and repeated failures reproducible.

The logical models in `xHal_Rpi5CarLogicalModels.h` describe bounded logical behavior, not physical vehicle
dynamics. They apply clamped motor commands with acceleration and deceleration limits, steering clamps around a
configured centre and travel, deterministic battery reduction with warning (default 7.2 V) and critical (default
6.6 V) thresholds, bounded grayscale and ultrasonic sequences, delayed or frozen camera frames, periodic I2C
failures, and a safe state that invalidates movement after a terminal fault. Sequences hold at most 1,024 values,
and the event log holds at most 512 events, counting any dropped events.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/simulation/xWalkRobotHat`
(source directory)

## 3. Directory layout

```text
xWalkRobotHat/
├── CMakeLists.txt                                      Simulator library, host test, and soak test
├── include/
│   ├── xHal_Rpi5CarRobotHatSimulation.h                I2C, GPIO, and camera callback simulator
│   └── xHal_Rpi5CarLogicalModels.h                     Bounded logical behavioral models
├── src/
│   ├── xHal_Rpi5CarRobotHatSimulation.cpp
│   └── xHal_Rpi5CarLogicalModels.cpp
└── test/
    ├── include/
    │   ├── xHal_Rpi5CarRobotHatSimulationTestSupport.h Shared test support declarations
    │   └── xHal_Rpi5CarRobotHatSoakTypes.h             Soak-run types
    └── src/
        ├── xHal_Rpi5CarRobotHatSimulationTest.cpp      Simulator behavior and fault injection
        ├── xHal_Rpi5CarLogicalModelsTest.cpp           Logical-model behavior
        ├── xHal_Rpi5CarRobotHatSimulationTestSupport.cpp
        └── xHal_Rpi5CarRobotHatSoak.cpp                Seeded soak executable with a JSON report
```

## 4. Public interface

Both headers declare their types in the `xwalk::hal::simulation` namespace.

- `XWalkRobotHatSimulation` is non-copyable and non-movable. It exposes `gpioCallbacks()` and static `probe`,
  `writeRegister`, `tryWriteRegister`, `read`, `readRegister`, GPIO configure, read, write, interrupt, and cancel
  callbacks, plus camera `capture`, for constructing production interface objects.
- Configuration methods: `setI2cPresent()`, `setAdcValue()`, `setGrayscaleValues()`, `setBatteryVoltage()`,
  `setUltrasonicDistance()`, `setGpioValue()`, `setCameraAvailable()`, `setCameraFrames()`, and
  `setLogicalDelay()`.
- Fault and inspection methods: `failNext()`, `clearFailures()`, `events()`, `clearEvents()`, `registerValue()`,
  `gpioValue()`, `ultrasonicDistance()`, and `nextCameraFrame()`.
- `XWalkRobotHatEvent` records sequence, logical time, operation, target, value, success, data, and text.
- Logical-model functions: `validateLogicalModelConfiguration()`, `initializeLogicalModel()`,
  `commandLogicalMotors()`, `advanceLogicalModel()`, `commandLogicalSteering()`, `nextLogicalGrayscale()`,
  `nextLogicalUltrasonic()`, `nextLogicalCameraFrame()`, `logicalI2cOperationFails()`, and
  `enterLogicalSafeState()`. They return `XWalkLogicalModelStatus`.

## 5. Build

The static library `xWalkRobotHatSimulation` (alias `xWalk::RobotHatSimulation`) links `xWalkI2c`, `xWalkGpio`,
and `xWalkCamera` publicly and `xWalkTrace` privately. From the `xWalk-rpi5-hw` directory, the `host-debug`
preset writes its build to `../build-host/cmake`:

```bash
cmake --preset host-debug
cmake --build ../build-host/cmake --target xWalkRobotHatSimulationTest xWalkRobotHatSoakTest xWalkPicarxSimulationTest
```

## 6. Testing

```bash
ctest --test-dir ../build-host/cmake -L simulation --output-on-failure
```

| CTest name | Executable | Labels |
|---|---|---|
| `xWalkRobotHatSimulationHostTest` | `xWalkRobotHatSimulationTest` | `host;simulation;fault-injection` |
| `xWalkRobotHatSoakHostTest` | `xWalkRobotHatSoakTest` | `host;simulation;soak;fault-injection` |

The soak test runs with `--seed 42 --iterations 5000 --logical-duration 10000 --fault-rate 0.05` and writes
`xwalk-robot-hat-soak-report.json` to its build directory, with a 30-second CTest timeout. The `simulation` label
also selects `xWalkPicarxSimulationHostTest` (executable `xWalkPicarxSimulationTest`), which is owned by
the PiCar-X driver and composes it with this simulator.

The PiCar-X simulator composition uses the Robot HAT v5 dual-PWM motor mapping: P12/P13 for motor one and P14/P15
for motor two. It verifies software mapping and failure behavior only.

## 7. Dependencies

- `xWalkI2c`, `xWalkGpio`, `xWalkCamera`, and `xWalkTrace`.
- The host test also links `xWalkAdc` and `xWalkPwm`.

## 8. Safety and constraints

- The simulator is host-only and is never selected by the Raspberry Pi build.
- Physical port assignment, polarity, servo calibration, electrical behavior, and Raspberry Pi 5 timing still
  require the raised-wheel commissioning procedure on the actual kit.
- Simulator callbacks are serialized internally by a mutex; returned event snapshots are owned copies.

## 9. Related notes

- [xWalkHal](../../xWalkHal.md)
- [xWalkI2c](../../interface/xWalkI2c/xWalkI2c.md)
- [xWalkGpio](../../interface/xWalkGpio/xWalkGpio.md)
- [xWalkCamera](../../device/xWalkCamera/xWalkCamera.md)
- [xWalkPicarx](../../../xWalkDriver/xWalkVehicle/xWalkPicarx/xWalkPicarx.md)

---

[Previous page](../../sensor/xWalkMotor/simulation/xWalkMotor%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](../../../xWalkLibrary/xWalkLibrary.md)
