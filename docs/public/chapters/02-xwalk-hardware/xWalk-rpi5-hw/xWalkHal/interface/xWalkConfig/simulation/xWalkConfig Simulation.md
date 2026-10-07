<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkConfig
Simulation

**2. xWalk hardware &middot; Module 71**

<!-- xwalk-page-header:end -->

# xWalkConfig Simulation

The standalone `xWalkConfigSimulation` executable exercises `XWalkConfig` and `XWalkConfigStore` through their
production filesystem behavior without inspecting or modifying deployed application configuration.

## 1. Overview

The simulation writes a `motor` section (`speed = 42`, `mode = safe`) to `simulation.ini` and a `calibration`
key to `simulation.config`, then reconstructs both objects and verifies that the values persisted. All files
are written beneath `<build directory>/simulation-data`, fixed at configure time through
`XWALK_CONFIG_SIMULATION_DATA_PATH`. There is no hardware backend.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/simulation` -
source directory

## 3. Directory layout

```text
simulation/
    CMakeLists.txt                                   Standalone project
    config/xHal_Rpi5CarConfigTraceConfig.py          Validates and merges the persistent trace catalogue
    include/
        xHal_Rpi5CarConfigSimulation.h               Simulation entry point
        xHal_Rpi5CarConfigSimulationArguments.h      Trace-option parsing
        xHal_Rpi5CarConfigSimulationConfig.h         Trace configuration, log, and data paths
    src/
        main.cpp                                     Executable entry point
        xHal_Rpi5CarConfigSimulation.cpp             Persist-and-reload scenario
        xHal_Rpi5CarConfigSimulationArguments.cpp    Selector validation and persistence
```

## 4. Build

From the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/simulation -B xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/simulation/build-host --target xWalkConfigSimulation --parallel
```

```bash
xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/simulation/build-host/xWalkConfigSimulation --trace RPI.enable
```

## 5. Configuration

Selectors accept `RPI.<digits>`, the complete `RPI` tag, or `all` with `.enable` or `.disable`, or a JSON
trace-update file. Successful changes are stored in `generated/xWalkConfigTrace.xml` for the next run. Enabled
messages appear in the terminal and `<build directory>/log/xWalkConfigSimulation.log`.

## 6. Dependencies

`xWalkConfig`, `xWalkTrace`, and Python 3 for the trace catalogue.

## 7. Related notes

- [xWalkConfig](../xWalkConfig.md)
- [xWalkHal Interface Layer](../../xWalkHal%20Interface%20Layer.md)

---

[Previous page](../xWalkConfig.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkGpio/xWalkGpio.md)
