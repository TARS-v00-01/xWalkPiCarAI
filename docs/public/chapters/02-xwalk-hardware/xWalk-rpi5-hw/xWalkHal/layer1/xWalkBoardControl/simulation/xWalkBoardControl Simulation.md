<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) /
xWalkBoardControl Simulation

**2. xWalk hardware &middot; Module 89**

<!-- xwalk-page-header:end -->

# xWalkBoardControl Simulation

The `xWalkBoardControlSimulation` executable exercises board reset, battery conversion, speaker priming,
firmware acquisition, and synthetic Robot HAT discovery through in-memory callbacks and a build-local device-tree
fixture.

## 1. Overview

The simulation uses named in-memory GPIO, I2C, ADC, firmware, and speaker-prime adapters provided by
`XWalkBoardControlHostStub`, plus a synthetic device tree created below the build directory. It does not access
physical GPIO, I2C, ALSA, or `/proc/device-tree` resources.

Trace changes requested on the command line persist in a generated XML catalogue, and a later run without a
selector loads the saved state. Enabled messages appear in the terminal and in
`build-host/log/xWalkBoardControlSimulation.log`. The simulation emits trace IDs `RPI.331` (start) and `RPI.332`
(completion).

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl/simulation`
(source directory)

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                  Standalone simulation project
├── config/                         Persistent trace catalogue generator script
├── include/
│   ├── *HostStub.h                 In-memory dependencies used by the scenario
│   ├── *SimulationArguments.h      --help and --trace parsing
│   ├── *SimulationConfig.h         Default trace, log, and device-tree paths
│   └── *Simulation.h               Scenario entry point
└── src/
    ├── main.cpp                    Trace configuration, argument handling, and scenario run
    └── *.cpp                       HostStub, SimulationArguments, and Simulation implementations
```

Every header and source file carries the `xHal_Rpi5CarBoardControl` prefix.

## 4. Build

The project adds the parent module with its host and hardware test options forced `OFF`. Run these commands from
this `simulation` directory:

```bash
cmake -S . -B build-host -DCMAKE_BUILD_TYPE=Debug
cmake --build build-host --target xWalkBoardControlSimulation --parallel
./build-host/xWalkBoardControlSimulation --trace RPI.enable
```

## 5. Configuration

The executable accepts no argument, `--help` or `-h`, or `--trace <selector>`:

- `<target>.enable` or `<target>.disable`, where the target is `RPI`, `all`, or `RPI.<number>`.
- A path ending in `.json`, applied as a global trace argument.

An invalid argument, or a selector whose identifier is absent from the trace inventory, exits with status 2.

At build time, the script `config/xHal_Rpi5CarBoardControlTraceConfig.py` validates the workspace trace inventory
and merges it into `generated/xWalkBoardControlTrace.xml`, preserving the global, module, and per-trace states
saved by earlier runs. CMake passes build-local paths through compile definitions; the configuration header
supplies source-visible defaults.

- `XWALK_BOARD_CONTROL_SIMULATION_TRACE_CONFIG_PATH`: header default `xwalk-traces.xml`, build value
  `<build>/generated/xWalkBoardControlTrace.xml`.
- `XWALK_BOARD_CONTROL_SIMULATION_TRACE_LOG_PATH`: header default `log/xWalkBoardControlTrace.log`, build value
  `<build>/log/xWalkBoardControlSimulation.log`.
- `XWALK_BOARD_CONTROL_SIMULATION_DEVICE_TREE_PATH`: header default `device-tree`, build value
  `<build>/device-tree`.

## 6. Testing

The simulation itself is not registered with CTest. Its argument parser is also compiled into the module host
test, and `xGoogleTest` checks its trace-argument boundaries in `TEST_SUITE_XWALK_SIMULATION`.

## 7. Dependencies

- `xWalkBoardControl` and `xWalkTrace`.
- Python 3 for trace-catalogue generation, and the `xWalkTraceMetadata` target for the trace inventory.

## 8. Safety and constraints

The simulation is host-only and device-free. It never opens GPIO, I2C, ALSA, or `/proc/device-tree`; the device
tree it reads is synthetic.

## 9. Related notes

- [xWalkBoardControl](../xWalkBoardControl.md)
- [xWalkHal Layer1](../../xWalkHal%20Layer1.md)
- [xWalk-rpi5-trace](../../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkBoardControl.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkGPT/xWalkGPT.md)
