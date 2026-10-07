<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkRobot
Simulation

**2. xWalk hardware &middot; Module 96**

<!-- xwalk-page-header:end -->

# xWalkRobot Simulation

The `xWalkRobotSimulation` executable exercises registration, initialization, calibration, offset
persistence, reset, interpolation, and action playback through an in-memory servo bus and a build-local
configuration file.

## 1. Overview

The scenario creates one simulated Servo/PWM chain on an in-memory I2C adapter, `XWalkRobotHostStub`, which
records servo register writes. It sets offsets, origins, directions, and calibration positions, runs calibration
and reset, then defines and plays a `nod` action. The build-local configuration store is removed after the run.
It cannot move physical hardware.

Trace changes requested on the command line persist in a generated XML catalogue, and a later run without a
selector loads the saved state. Enabled messages appear in the terminal and in
`build-host/log/xWalkRobotSimulation.log`. The simulation emits trace IDs `RPI.353` (start) and `RPI.354`
(completion).

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot/simulation`
(source directory)

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                  Standalone simulation project
├── config/                         Persistent trace catalogue generator script
├── include/
│   ├── *HostStub.h                 In-memory dependencies used by the scenario
│   ├── *SimulationArguments.h      --help and --trace parsing
│   ├── *SimulationConfig.h         Default trace, log, and store paths
│   └── *Simulation.h               Scenario entry point
└── src/
    ├── main.cpp                    Trace configuration, argument handling, and scenario run
    └── *.cpp                       HostStub, SimulationArguments, and Simulation implementations
```

Every header and source file carries the `xHal_Rpi5CarRobot` prefix.

## 4. Build

The project adds the parent module with its host and hardware test options forced `OFF`. Run these commands from
this `simulation` directory:

```bash
cmake -S . -B build-host -DCMAKE_BUILD_TYPE=Debug
cmake --build build-host --target xWalkRobotSimulation --parallel
./build-host/xWalkRobotSimulation --trace RPI.enable
```

## 5. Configuration

The executable accepts no argument, `--help` or `-h`, or `--trace <selector>`:

- `<target>.enable` or `<target>.disable`, where the target is `RPI`, `all`, or `RPI.<number>`.
- A path ending in `.json`, applied as a global trace argument.

An invalid argument, or a selector whose identifier is absent from the trace inventory, exits with status 2.

At build time, the script `config/xHal_Rpi5CarRobotTraceConfig.py` validates the workspace trace inventory and
merges it into `generated/xWalkRobotTrace.xml`, preserving the global, module, and per-trace states saved by
earlier runs. CMake passes build-local paths through compile definitions; the configuration header supplies
source-visible defaults.

- `XWALK_ROBOT_SIMULATION_TRACE_CONFIG_PATH`: header default `xwalk-traces.xml`, build value
  `<build>/generated/xWalkRobotTrace.xml`.
- `XWALK_ROBOT_SIMULATION_TRACE_LOG_PATH`: header default `log/xWalkRobotTrace.log`, build value
  `<build>/log/xWalkRobotSimulation.log`.
- `XWALK_ROBOT_SIMULATION_STORE_PATH`: header default `robot-simulation.config`, build value
  `<build>/data/robot.config`.

## 6. Testing

The simulation itself is not registered with CTest. Its argument parser is also compiled into the module host
test, and `xGoogleTest` checks its trace-argument boundaries in `TEST_SUITE_XWALK_SIMULATION`.

## 7. Dependencies

- `xWalkRobot` and `xWalkTrace`.
- Python 3 for trace-catalogue generation, and the `xWalkTraceMetadata` target for the trace inventory.

## 8. Safety and constraints

The simulation is host-only and device-free. It never opens an I2C device and cannot move a servo.

## 9. Related notes

- [xWalkRobot](../xWalkRobot.md)
- [xWalkHal Layer1](../../xWalkHal%20Layer1.md)
- [xWalk-rpi5-trace](../../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkRobot.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkSpeaker/xWalkSpeaker.md)
