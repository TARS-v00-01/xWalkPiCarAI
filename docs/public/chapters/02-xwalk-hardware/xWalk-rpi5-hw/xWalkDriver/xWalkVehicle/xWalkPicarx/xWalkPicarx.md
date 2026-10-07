<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkPicarx

**2. xWalk hardware &middot; Module 23**

<!-- xwalk-page-header:end -->

# xWalkPicarx

`xWalkPicarx` is the C++17 PiCar-X application coordinator shared by every motion Agent. It delegates
physical I/O to the existing motor, servo, grayscale, ultrasonic, and configuration HAL modules and owns none
of those dependencies.

## 1. Overview

- construction loads and validates configuration without moving any servo;
- explicit `initialize()` initializes the steering, pan, and tilt PWM paths, applies the persisted calibrated
  positions only when `picarx_apply_persisted_servo_positions` is `true`, and arms the paired motor
  controller;
- loads and persists the upstream `picarx_*`, `line_reference`, and `cliff_reference` keys;
- exposes non-persistent servo-offset and motor-direction previews for calibration Agents;
- clamps steering to -30 through 30 degrees, pan to -90 through 90 degrees, and tilt to -35 through 65
  degrees;
- applies requested power directly as a percentage, without the upstream 50-percent minimum boost;
- applies motor-balance calibration and steering compensation before the configured output ceiling;
- provides latched emergency actuator suppression and scope-bound non-throwing paired-motor shutdown;
- exposes a non-throwing motor-watchdog refresh for bounded movement coordinators;
- reduces the inside wheel according to the current steering angle while using the HAL's logical motor
  direction;
- exposes raw grayscale data, threshold classification, cliff detection, and ultrasonic distance in
  centimeters;
- resets all logical actuator commands during `close()` and cancels ultrasonic interrupt registrations.

`initialize()` is the required application lifecycle boundary. Drive commands are rejected before it
succeeds, and a failed initialization rolls back through the emergency stop, leaving motor movement
unavailable. An emergency stop disarms the motors; clearing the emergency latch first re-establishes a stopped
output and re-arms them.

The upstream constructor resets the Robot HAT MCU before motor GPIO 5 is claimed. This port performs that step
in the RPi composition root so the temporary reset GPIO backend can be destroyed before the right motor claims
the same physical line. Applications must follow the same ordering before constructing `XWalkPicarx`.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVehicle/xWalkPicarx`
(source directory)

## 3. Directory layout

```text
xWalkPicarx/
    CMakeLists.txt                                   Library, configuration path, and test registration
    include/
        xAgent_Rpi5CarPicarx.h                       Public coordinator contract and non-owning dependencies
        xAgent_Rpi5CarPicarxConfiguration.h          Build-time config-path declaration and fallback
        xAgent_Rpi5CarPicarxSafetyGuard.h            Scope-bound emergency-stop contract
    src/
        xAgent_Rpi5CarPicarxLifecycle.cpp            Dependency binding and persisted configuration loading
        xAgent_Rpi5CarPicarxDrive.cpp                Motor scaling, steering, watchdog, stop, reset, and close
        xAgent_Rpi5CarPicarxSafetyGuard.cpp          Command-scope emergency-stop cleanup
        xAgent_Rpi5CarPicarxCalibration.cpp          Servo and motor calibration persistence
        xAgent_Rpi5CarPicarxSensing.cpp              Grayscale, cliff, and ultrasonic delegation
        xAgent_Rpi5CarPicarxValidation.cpp           Finite numeric and persisted-list validation
    test/
        include/                                     Test types and reusable test-support declarations
        src/xAgent_Rpi5CarPicarxTest.cpp             Deterministic host behavior tests
        src/xAgent_Rpi5CarPicarxSimulationTest.cpp   Lifecycle and safety through the Robot HAT simulator
        src/xAgent_Rpi5CarPicarxTestSupport.cpp      Shared simulation test support
        hardware/src/xAgent_Rpi5CarPicarxHardwareTest.cpp  Opt-in physical reset-and-stop smoke test
```

## 4. Public interface

`xwalk::agent::XWalkPicarx` is constructed from an `xAgentContext` (declared in `xWalk_Rpi5CarAgentConfigType.h`
of [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)). Populate the PiCar-X
dependency fields `config`, `motors`, `dirServo`, `panServo`, `tiltServo`, `grayscale`, and `ultrasonic`. The
context and every referenced HAL object remain caller-owned; all required PiCar-X fields must be non-null.

| Area | Members |
| --- | --- |
| Lifecycle | `initialize()`, `isInitialized()`, `reset()`, `close()` |
| Drive | `forward()`, `backward()`, `setPower()`, `setMotorSpeed()`, `stop()`, `reverseFromObstacle()` |
| Steering | `setDirectionServoAngle()`, `directionAngleDegrees()` |
| Camera | `setCameraPanAngle()`, `setCameraTiltAngle()` |
| Safety | `emergencyStop()`, `clearEmergencyStop()`, `emergencyStopRequested()`, `refreshMotorWatchdog()` |
| Calibration | `calibrate*()` persistent setters, `preview*()` non-persistent previews, matching getters |
| Commissioning | `maximumMotorOutputPercent()`, `recordCalibrationVerified()`, `calibrationVerified()` |
| Sensing | `grayscaleData()`, `lineStatus()`, `cliffStatus()`, `distance()` |
| References | `setGrayscaleReference()`, `grayscaleReference()`, `setCliffReference()`, `cliffReference()` |

`reverseFromObstacle(power, steering, leaseMs)` steers within ±30 degrees and requests a lease-bounded reverse
through the motor HAL's reverse-inhibit path; the Controller validates the request and owns device admission
before the call.

`xwalk::agent::XWalkPicarxSafetyGuard` binds one `XWalkPicarx` and performs the non-throwing emergency stop when
the guarded command scope ends.

## 5. Configuration

The persisted file is selected by the `XWALK_PICARX_CONFIG_FILE` cache value, which defaults to the Controller
`picar-x.conf`.
Official CMake targets replace the source-visible relative configuration path in
`xAgent_Rpi5CarPicarxConfiguration.h` with this absolute cache value.

| Key | Meaning |
| --- | --- |
| `picarx_dir_servo`, `picarx_cam_pan_servo`, `picarx_cam_tilt_servo` | Servo calibration offsets |
| `picarx_dir_motor` | Two logical motor directions |
| `picarx_motor_speed_calibration` | Balance correction from -100 through 100 percentage points |
| `picarx_max_motor_output_percent` | Deployment output ceiling from 0 through 100 percent, default 100 |
| `picarx_calibration_verified` | Exactly `true` or `false`; records commissioning status |
| `picarx_apply_persisted_servo_positions` | Exactly `true` or `false`; applies offsets during `initialize()` |
| `line_reference`, `cliff_reference` | Three-channel grayscale references |

`picarx_calibration_verified` records commissioning status without clamping power. At zero balance
correction and straight steering, a 30-percent command applies 30-percent PWM. Low requested power may be
insufficient to overcome a particular motor's starting friction. For `picarx_motor_speed_calibration`,
positive values reduce the left side and negative values reduce the right side. Missing values default to
zero; malformed and out-of-range persisted values are rejected during construction.

## 6. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_PICARX_BUILD_HOST_TESTS` | `OFF` | Builds the host and simulation tests |
| `XWALK_PICARX_BUILD_HARDWARE_TESTS` | `OFF` | Builds the Linux/RPi hardware test; requires Linux |
| `XWALK_PICARX_CONFIG_FILE` | `picar-x.conf` path above | Writable PiCar-X calibration file |
| `XWALK_PICARX_HAL_ROOT` | `../../../xWalkHal` | HAL source tree used for dependencies |

The module builds `xWalkPicarx` (alias `xWalk::Picarx`). It adds `xWalkConfig`, `xWalkTrace`,
`xWalkLineTracker`, `xWalkMotor`, `xWalkServo`, and `xWalkUltrasonic` when not already defined, with their host
tests forced off. The hardware option also enables the HAL hardware tests and adds `xWalkBoardControl`.

## 7. Testing

| Test | Labels | Content |
| --- | --- | --- |
| `xWalkPicarxHostTest` | `host` | Deterministic behavior tests on a private `test-data/host` configuration |
| `xWalkPicarxSimulationHostTest` | `host`, `simulation`, `fault-injection`, `lifecycle` | Robot HAT simulator |
| `xWalkPicarxHardwareResetTest` | `hardware` | Physical reset-and-stop smoke test |

The simulation test is registered only when the `xWalkRobotHatSimulation` target exists.

```bash
ctest --test-dir build-host/cmake --output-on-failure -R xWalkPicarx
```

The hardware test detects the Robot HAT revision, composes its Linux backends, resets the MCU, and invokes the
safe close state. It uses `XWALK_AGENT_HARDWARE_V4_CONFIG_FILE` when defined; the Controller CMake
configuration generates that Robot HAT v4 profile at `config/xwalk-agent-hardware-v4.conf` under
`CMAKE_BINARY_DIR`. Otherwise it uses `XWALK_PICARX_CONFIG_FILE`. Validate the generated configuration before
use. Hardware tests remain off by default; discover them with `ctest -N -L hardware` and do not run them
without explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- [xWalkConfig](../../../xWalkHal/interface/xWalkConfig/xWalkConfig.md),
  [xWalkLineTracker](../../../xWalkHal/sensor/xWalkLineTracker/xWalkLineTracker.md),
  [xWalkMotor](../../../xWalkHal/sensor/xWalkMotor/xWalkMotor.md),
  [xWalkServo](../../../xWalkHal/device/xWalkServo/xWalkServo.md), and
  [xWalkUltrasonic](../../../xWalkHal/device/xWalkUltrasonic/xWalkUltrasonic.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).
- [xWalkBoardControl](../../../xWalkHal/layer1/xWalkBoardControl/xWalkBoardControl.md) and the Linux I2C and
  GPIO backends for the hardware test.

## 9. Safety and constraints

Keep `picarx_apply_persisted_servo_positions` false until steering, pan, and tilt limits have been
commissioned with mechanically unloaded servos. Every active motor command expires unless the watchdog is
refreshed. Physical use moves the drive motors and all three servos.

The module emits `RPIAGENT.001` during lifecycle, `RPIAGENT.081` when a safety guard is armed, and
`RPIAGENT.082` when a grayscale reference update is requested; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 10. Related notes

- [xWalkVehicle](../xWalkVehicle.md)
- [xWalkController](../../../xWalkController/xWalkController.md)
- [xWalkRobotHat](../../../xWalkHal/simulation/xWalkRobotHat/xWalkRobotHat.md)

---

[Previous page](../xWalkObstacleAvoidance/xWalkObstacleAvoidance.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkSelfDrive/xWalkSelfDrive.md)
